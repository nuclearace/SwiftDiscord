// The MIT License (MIT)
// Copyright (c) 2016 Erik Little

// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated
// documentation files (the "Software"), to deal in the Software without restriction, including without
// limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the
// Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

// The above copyright notice and this permission notice shall be included in all copies or substantial portions of the
// Software.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING
// BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO
// EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
// ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
// DEALINGS IN THE SOFTWARE.

import Foundation
import Dispatch

internal typealias DiscordRequestCallback = (Data?, HTTPURLResponse?, Error?) -> ()
private typealias RateLimitedRequest = (request: URLRequest, callback: DiscordRequestCallback)

/// The DiscordRateLimiter is in charge of making sure we don't flood Discord with requests.
/// It keeps a dictionary of DiscordRateLimitKeys and DiscordRateLimits.
/// All requests to the REST api should be routed through the DiscordRateLimiter.
/// If a DiscordRateLimit determines we have hit a limit, we add the request and its callback to the limit's queue.
/// After that it is up to the DiscordRateLimit to decide when to make the request.
/// TODO handle the global rate limit
public final class DiscordRateLimiter {
    private let session = URLSession(configuration: .default, delegate: nil, delegateQueue: OperationQueue())

    private var limitQueue = DispatchQueue(label: "limitQueue")
    private var endpointLimits = [DiscordRateLimitKey: DiscordRateLimit]()

    // MARK: Methods

    /**
        Executes a request through the rate limiter. If the rate limit is hit, the request is put in a queue
        and executed later.

        - parameter request: The request to execute.
        - parameter for: The endpoint key.
        - parameter callback: The callback for this request.
    */
    public func executeRequest(_ request: URLRequest, for endpointKey: DiscordRateLimitKey,
                               callback: @escaping (Data?, HTTPURLResponse?, Error?) -> ()) {
        func _executeRequest() {
            if endpointLimits[endpointKey] == nil {
                // First time handling this endpoint, err on the side caution and limit to one
                endpointLimits[endpointKey] = DiscordRateLimit(endpointKey: endpointKey, limit: 1, remaining: 1,
                                                               reset: Int(Date().timeIntervalSince1970) + 3)
            }

            let rateLimit = endpointLimits[endpointKey]!

            if rateLimit.atLimit {
                DefaultDiscordLogger.Logger.debug("Hit rate limit: \(rateLimit)", type: "DiscordRateLimiter")

                // We've hit a rate limit, enqueue this request for later
                rateLimit.queue.append(RateLimitedRequest(request: request, callback: callback))

                return
            }

            rateLimit.remaining -= 1

            DefaultDiscordLogger.Logger.debug("Doing request: \(request), remaining: \(rateLimit.remaining)", type: "DiscordRateLimiter")

            session.dataTask(with: request,
                             completionHandler: createResponseHandler(for: request, endpointKey: endpointKey,
                                                                      callback: callback)).resume()
        }

        limitQueue.async(execute: _executeRequest)
    }

    public func executeRequest(endpoint: DiscordEndpoint,
                               token: DiscordToken,
                               requestInfo: DiscordEndpoint.EndpointRequest,
                               callback: @escaping (Data?, HTTPURLResponse?, Error?) -> ()) {
        let rateLimitKey = DiscordRateLimitKey(endpoint: endpoint.endpointForRateLimiter)
        guard let request = requestInfo.createRequest(with: token, endpoint: endpoint) else {
            // Error is logged by createRequest
            return
        }

        executeRequest(request, for: rateLimitKey, callback: callback)
    }

    private func createResponseHandler(for request: URLRequest, endpointKey: DiscordRateLimitKey,
                                       callback: @escaping DiscordRequestCallback) -> (Data?, URLResponse?, Error?) -> () {
        func _createResponseHandler(data: Data?, response: URLResponse?, error: Error?) {
            func _responseHandler() {
                let rateLimit = endpointLimits[endpointKey]!

                defer { rateLimit.scheduleReset(on: limitQueue, with: self) }

                guard let response = response as? HTTPURLResponse else {
                    // Not quite sure what happened
                    callback(data, nil, error)

                    return
                }

                guard error == nil else {
                    callback(data, response, error)

                    return
                }

                guard response.statusCode != 429 else {
                    // Hit rate limit
                    rateLimit.queue.append(RateLimitedRequest(request: request, callback: callback))

                    return
                }

                if let limit = response.allHeaderFields["x-ratelimit-limit"],
                   let remaining = response.allHeaderFields["x-ratelimit-remaining"],
                   let reset = response.allHeaderFields["x-ratelimit-reset"] {
                    // Update the limit and attempt to schedule a limit reset
                    rateLimit.updateLimits(limit: Int(limit as! String)!,
                                           remaining: Int(remaining as! String)!,
                                           reset: Int(reset as! String)!)
                }

                DefaultDiscordLogger.Logger.debug("New limit: \(rateLimit.limit)", type: "DiscordRateLimiter")
                DefaultDiscordLogger.Logger.debug("New remaining: \(rateLimit.remaining)", type: "DiscordRateLimiter")
                DefaultDiscordLogger.Logger.debug("New reset: \(rateLimit.reset)", type: "DiscordRateLimiter")

                callback(data, response, error)
            }

            limitQueue.async(execute: _responseHandler)
        }

        return _createResponseHandler
    }
}

/// An endpoint is made up of a REST api endpoint and any major parameters in that endpoint.
/// Ex. /channels/232184444340011009/messages and /channels/186926276592795659/messages
/// Are considered different endpoints
public struct DiscordRateLimitKey: Hashable {
    // MARK: Properties

    /// The guild or channel ID in this endpoint (or "" if neither)
    public let key: String

    /// The hash of the key.
    public var hashValue: Int {
        return key.hashValue
    }

    // MARK: Initializers

    /// Creates a new endpoint key.
    public init(endpoint: DiscordEndpoint) {
		if case let .channelMessageDelete(channel, _) = endpoint {
			self.key = DiscordEndpoint.messages(channel: channel).description + "d"
		} else {
			self.key = endpoint.description
		}
    }

    /// Whether two keys are equal.
    public static func ==(lhs: DiscordRateLimitKey, rhs: DiscordRateLimitKey) -> Bool {
        return lhs.key == rhs.key
    }
}

/// A DiscordRateLimit's job is to keep track of a endpoint's rate limit.
/// If we told the DiscordRateLimiter we hit a limit, it will add the request to the Limit's queue.
/// Enqueued requests are handled through limit resets. Which are told to us by Discord in the x-ratelimit-reset header.
/// It's up to the DiscordRateLimiter to actually call the scheduleReset method.
private final class DiscordRateLimit {
    var limit: Int
    var remaining: Int
    var reset: Int
    var queue = [RateLimitedRequest]()

    private let endpointKey: DiscordRateLimitKey

    private var scheduledReset = false

    var atLimit: Bool {
        return remaining <= 0
    }

    private var deadlineForReset: DispatchTime {
        let seconds = reset - Int(Date().timeIntervalSince1970)

        guard seconds > 0 else { return DispatchTime(uptimeNanoseconds: 0) }

        return DispatchTime.now() + Double(seconds)
    }

    init(endpointKey: DiscordRateLimitKey, limit: Int, remaining: Int, reset: Int) {
        self.endpointKey = endpointKey
        self.limit = limit
        self.remaining = remaining
        self.reset = reset
    }

    func scheduleReset(on queue: DispatchQueue, with limiter: DiscordRateLimiter) {
        guard !scheduledReset else { return }

        scheduledReset = true

        queue.asyncAfter(deadline: deadlineForReset) {
            DefaultDiscordLogger.Logger.debug("Reset triggered: \(self.endpointKey)", type: "RateLimit")
            self.remaining = self.limit
            self.scheduledReset = false

            guard self.queue.count != 0 else { return }

            var removed = 0

            repeat {
                let limitedRequest = self.queue.removeFirst()

                limiter.executeRequest(limitedRequest.request, for: self.endpointKey, callback: limitedRequest.callback)

                removed += 1
            } while removed < self.remaining && self.queue.count != 0

            DefaultDiscordLogger.Logger.debug("Sent \(removed) requests for limit: \(self.endpointKey)", type: "RateLimit")
        }
    }

    func updateLimits(limit: Int, remaining: Int, reset: Int) {
        self.limit = limit
        self.remaining = remaining
        self.reset = reset
    }
}
