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

/// The DiscordRateLimiter is in charge of making sure we don't flood Discord with requests.
/// It keeps a dictionary of DiscordRateLimitKeys and DiscordRateLimits.
/// All requests to the REST api should be routed through the DiscordRateLimiter.
/// If a DiscordRateLimit determines we have hit a limit, we add the request and its callback to the limit's queue
/// after that it is up to the DiscordRateLimit to decide when to make the request.
/// TODO handle the global rate limit
final class DiscordRateLimiter {
    static let shared = DiscordRateLimiter()

    private static let sharedSession = URLSession(configuration: .default, delegate: nil,
                                                  delegateQueue: OperationQueue())
    private static var limitQueue = DispatchQueue(label: "limitQueue")

    private var endpointLimits = [DiscordRateLimitKey: DiscordRateLimit]()

    private init() {}

    static func executeRequest(_ request: URLRequest, for endpointKey: DiscordRateLimitKey,
            callback: @escaping (Data?, HTTPURLResponse?, Error?) -> ()) {
        limitQueue.async {
            if DiscordRateLimiter.shared.endpointLimits[endpointKey] == nil {
                // First time handling this endpoint, err on the side caution and limit to one
                DiscordRateLimiter.shared.endpointLimits[endpointKey] =
                    DiscordRateLimit(endpointKey: endpointKey, limit: 1, remaining: 1,
                        reset: Int(Date().timeIntervalSince1970) + 3)
            }

            let rateLimit = DiscordRateLimiter.shared.endpointLimits[endpointKey]!

            if rateLimit.atLimit {
                DefaultDiscordLogger.Logger.debug("Hit rate limit: %@", type: "DiscordRateLimiter", args: rateLimit)

                // We've hit a rate limit, enqueue this request for later
                rateLimit.queue.append(RateLimitedRequest(request: request, callback: callback))

                return
            }

            rateLimit.remaining -= 1

            DefaultDiscordLogger.Logger.debug("Doing request: %@, remaining: %@", type: "DiscordRateLimiter",
                args: request, rateLimit.remaining)

            sharedSession.dataTask(with: request,
                completionHandler: createHandleReponse(for: request, endpointKey: endpointKey, callback: callback)).resume()
        }
    }

    static func createHandleReponse(for request: URLRequest, endpointKey: DiscordRateLimitKey, callback:
            @escaping (Data?, HTTPURLResponse?, Error?) -> ()) -> (Data?, URLResponse?, Error?) -> () {
        return {data, response, error in
            limitQueue.async {
                let rateLimit = DiscordRateLimiter.shared.endpointLimits[endpointKey]!

                guard let response = response as? HTTPURLResponse else {
                    // Not quite sure what happened
                    rateLimit.scheduleReset(on: limitQueue)
                    callback(data, nil, error)

                    return
                }

                guard error == nil else {
                    rateLimit.scheduleReset(on: limitQueue)
                    callback(data, response, error)

                    return
                }

                guard response.statusCode != 429 else {
                    // Hit rate limit
                    rateLimit.queue.append(RateLimitedRequest(request: request, callback: callback))
                    rateLimit.scheduleReset(on: limitQueue)

                    return
                }

                if let limit = response.allHeaderFields["x-ratelimit-limit"],
                    let remaining = response.allHeaderFields["x-ratelimit-remaining"],
                    let reset = response.allHeaderFields["x-ratelimit-reset"] {
                        #if !os(Linux)
                        // Update the limit and attempt to schedule a limit reset
                        rateLimit.updateLimits(limit: Int(limit as! String)!,
                                               remaining: Int(remaining as! String)!,
                                               reset: Int(reset as! String)!)
                        #else
                        rateLimit.updateLimits(limit: Int(limit)!,
                                               remaining: Int(remaining)!,
                                               reset: Int(reset)!)
                        #endif
                        rateLimit.scheduleReset(on: limitQueue)
                } else {
                    rateLimit.scheduleReset(on: limitQueue)
                }

                DefaultDiscordLogger.Logger.debug("New limit: %@", type: "DiscordRateLimiter", args: rateLimit.limit)
                DefaultDiscordLogger.Logger.debug("New remaining: %@", type: "DiscordRateLimiter",
                    args: rateLimit.remaining)
                DefaultDiscordLogger.Logger.debug("New reset: %@", type: "DiscordRateLimiter", args: rateLimit.reset)

                callback(data, response, error)
            }
        }
    }
}

/// An endpoint is made up of a REST api endpoint and any major parameters in that endpoint.
/// Ex. /channels/232184444340011009/messages and /channels/186926276592795659/messages
/// Are considered different endpoints
struct DiscordRateLimitKey: Hashable {
    let key: String

    var hashValue: Int {
        return key.hashValue
    }

    init(endpoint: DiscordEndpoint, parameters: [String: String]) {
        var key = endpoint.rawValue

        for (param, value) in parameters {
            key = key.replacingOccurrences(of: param, with: value)
        }

        self.key = key
    }

    static func ==(lhs: DiscordRateLimitKey, rhs: DiscordRateLimitKey) -> Bool {
        return lhs.key == rhs.key
    }
}

private typealias RateLimitedRequest = (request: URLRequest, callback: (Data?, HTTPURLResponse?, Error?) -> ())

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

    func scheduleReset(on queue: DispatchQueue) {
        guard !scheduledReset else { return }

        scheduledReset = true

        queue.asyncAfter(deadline: deadlineForReset) {
            DefaultDiscordLogger.Logger.debug("Reset triggered: %@", type: "RateLimit", args: self.endpointKey)
            self.remaining = self.limit
            self.scheduledReset = false

            guard self.queue.count != 0 else { return }

            var removed = 0

            repeat {
                let limitedRequest = self.queue.removeFirst()

                DiscordRateLimiter.executeRequest(limitedRequest.request, for: self.endpointKey,
                    callback: limitedRequest.callback)

                removed += 1
            } while removed < self.remaining && self.queue.count != 0

            DefaultDiscordLogger.Logger.debug("Sent %@ requests for limit: %@", type: "RateLimit",
                args: removed, self.endpointKey)
        }
    }

    func updateLimits(limit: Int, remaining: Int, reset: Int) {
        self.limit = limit
        self.remaining = remaining
        self.reset = reset
    }
}
