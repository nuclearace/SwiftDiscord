// The MIT License (MIT)
// Copyright (c) 2016 Erik Little
// Copyright (c) 2021 fwcd

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
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

import Dispatch
import Logging

internal typealias DiscordRequestCallback = (Data?, HTTPURLResponse?, Error?) -> ()
private typealias RateLimitedRequest = (request: URLRequest, callback: DiscordRequestCallback)

fileprivate let logger = Logger(label: "DiscordRateLimiter")

/// The DiscordRateLimiter is in charge of making sure we don't flood Discord with requests.
/// It keeps a dictionary of DiscordRateLimitKeys and DiscordRateLimits.
/// All requests to the REST api should be routed through the DiscordRateLimiter.
/// If a DiscordRateLimit determines we have hit a limit, we add the request and its callback to the limit's queue.
/// After that it is up to the DiscordRateLimit to decide when to make the request.
/// TODO handle the global rate limit
public final class DiscordRateLimiter : DiscordRateLimiterSpec {
    /// The queue that request responses are called on.
    public let callbackQueue: DispatchQueue

    /// Whether or not this rate limiter should immediately callback on rate limits.
    public let failFast: Bool

    private let session = URLSession(configuration: .default, delegate: nil, delegateQueue: OperationQueue())

    private var limitQueue = DispatchQueue(label: "limitQueue")
    private var endpointLimits = [DiscordRateLimitKey: DiscordRateLimit]()

    // MARK: Initializers

    /// Creates a new DiscordRateLimiter with the specified callback queue.
    public init(callbackQueue: DispatchQueue, failFast: Bool) {
        self.callbackQueue = callbackQueue
        self.failFast = failFast
    }

    // MARK: Methods

    ///
    /// Executes a request through the rate limiter. If the rate limit is hit, the request is put in a queue
    /// and executed later.
    ///
    /// - parameter request: The request to execute.
    /// - parameter for: The endpoint key.
    /// - parameter callback: The callback for this request.
    ///
    public func executeRequest(_ request: URLRequest, for endpointKey: DiscordRateLimitKey,
                               callback: @escaping (Data?, HTTPURLResponse?, Error?) -> ()) {
        func _executeRequest() {
            if endpointLimits[endpointKey] == nil {
                // First time handling this endpoint, err on the side caution and limit to one
                endpointLimits[endpointKey] = DiscordRateLimit(endpointKey: endpointKey, limit: 1, remaining: 1,
                                                               reset: Date().timeIntervalSince1970 + 3)
            }

            let rateLimit = endpointLimits[endpointKey]!

            if rateLimit.atLimit {
                logger.debug("Hit rate limit: \(rateLimit)")

                guard !failFast else {
                    callbackQueue.async { callback(nil, nil, nil) }

                    return
                }

                // We've hit a rate limit, enqueue this request for later
                rateLimit.queue.append(RateLimitedRequest(request: request, callback: callback))

                return
            }

            rateLimit.remaining -= 1

            logger.debug("Doing request: \(request), remaining: \(rateLimit.remaining)")

            session.dataTask(with: request,
                             completionHandler: createResponseHandler(for: request, endpointKey: endpointKey,
                                                                      callback: callback)).resume()
        }

        limitQueue.async(execute: _executeRequest)
    }

    ///
    /// Executes a request through the rate limiter. If the rate limit is hit, the request is put in a queue
    /// and executed later.
    ///
    /// - parameter endpoint: The endpoint for this request.
    /// - parameter token: The token to use in this request.
    /// - parameter requestInfo: A `DiscordEndpoint.EndpointRequest` specifying the request info.
    /// - parameter callback: The callback for this request.
    ///
    public func executeRequest(endpoint: DiscordEndpoint,
                               token: DiscordToken,
                               requestInfo: DiscordEndpoint.EndpointRequest,
                               callback: @escaping (Data?, HTTPURLResponse?, Error?) -> ()) {
        guard let request = requestInfo.createRequest(with: token, endpoint: endpoint) else {
            // Error is logged by createRequest
            return
        }

        executeRequest(request, for: endpoint.rateLimitKey, callback: callback)
    }

    private func createResponseHandler(for request: URLRequest, endpointKey: DiscordRateLimitKey,
                                       callback: @escaping DiscordRequestCallback) -> (Data?, URLResponse?, Error?) -> () {
        func _createResponseHandler(data: Data?, response: URLResponse?, error: Error?) {
            func _responseHandler() {
                let rateLimit = endpointLimits[endpointKey]!

                defer { rateLimit.scheduleReset(on: limitQueue, with: self) }

                guard let response = response as? HTTPURLResponse else {
                    // Not quite sure what happened
                    callbackQueue.async { callback(data, nil, error) }

                    return
                }

                guard error == nil else {
                    callbackQueue.async { callback(data, response, error) }

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
                    rateLimit.updateLimits(limit: Double(limit as! String)!,
                                           remaining: Double(remaining as! String)!,
                                           reset: Double(reset as! String)!)
                }

                logger.debug("New limit: \(rateLimit.limit)")
                logger.debug("New remaining: \(rateLimit.remaining)")
                logger.debug("New reset: \(rateLimit.reset)")

                callbackQueue.async { callback(data, response, error) }
            }

            limitQueue.async(execute: _responseHandler)
        }

        return _createResponseHandler
    }
}


/// A DiscordRateLimiterSpec is in charge of making sure we don't flood Discord with requests.
/// It keeps a dictionary of DiscordRateLimitKeys and DiscordRateLimits.
/// All requests to the REST api should be routed through a DiscordRateLimiterSpec.
public protocol DiscordRateLimiterSpec {
    // MARK: Properties

    /// The queue that request responses are called on.
    var callbackQueue: DispatchQueue { get }

    /// Whether or not this rate limiter should immediately callback on rate limits.
    var failFast: Bool { get }

    // MARK: Methods

    ///
    /// Executes a request through the rate limiter.
    ///
    /// - parameter request: The request to execute.
    /// - parameter for: The endpoint key.
    /// - parameter callback: The callback for this request.
    ///
    func executeRequest(_ request: URLRequest, for endpointKey: DiscordRateLimitKey,
                        callback: @escaping (Data?, HTTPURLResponse?, Error?) -> ())

    ///
    /// Executes a request through the rate limiter.
    ///
    /// - parameter endpoint: The endpoint for this request.
    /// - parameter token: The token to use in this request.
    /// - parameter requestInfo: A `DiscordEndpoint.EndpointRequest` specifying the request info.
    /// - parameter callback: The callback for this request.
    ///
    func executeRequest(endpoint: DiscordEndpoint,
                        token: DiscordToken,
                        requestInfo: DiscordEndpoint.EndpointRequest,
                        callback: @escaping (Data?, HTTPURLResponse?, Error?) -> ())
}

/// An endpoint is made up of a REST api endpoint and any major parameters in that endpoint.
/// Ex. /channels/232184444340011009/messages and /channels/186926276592795659/messages
/// Are considered different endpoints
public struct DiscordRateLimitKey: Hashable, Identifiable {
    /// URL Parts for the purpose of rate limiting.
    /// Combine all the parts of the URL into a list of which parts exist
    /// Ex. /channels/232184444340011009/messages would be represented by [.channels, .channelID, .messages]
    /// Anything that ends in "ID" represents the existence of a snowflake id, but the actual ID should be
    /// stored separately if needed.  Technically, the .guildID and .channelID fields aren't needed since
    /// the full ID will also be stored, but they're included to make the system more straightforward.
    public struct DiscordRateLimitURLParts: OptionSet {
        public let rawValue: Int64

        static let           guilds = DiscordRateLimitURLParts(rawValue: 1 << 0)
        static let          guildID = DiscordRateLimitURLParts(rawValue: 1 << 1)
        static let         channels = DiscordRateLimitURLParts(rawValue: 1 << 2)
        static let        channelID = DiscordRateLimitURLParts(rawValue: 1 << 3)
        static let         messages = DiscordRateLimitURLParts(rawValue: 1 << 4)
        static let   messagesDelete = DiscordRateLimitURLParts(rawValue: 1 << 5)
        static let        messageID = DiscordRateLimitURLParts(rawValue: 1 << 6)
        static let       bulkDelete = DiscordRateLimitURLParts(rawValue: 1 << 7)
        static let           typing = DiscordRateLimitURLParts(rawValue: 1 << 8)
        static let      permissions = DiscordRateLimitURLParts(rawValue: 1 << 9)
        static let      overwriteID = DiscordRateLimitURLParts(rawValue: 1 << 10)
        static let          invites = DiscordRateLimitURLParts(rawValue: 1 << 11)
        static let       inviteCode = DiscordRateLimitURLParts(rawValue: 1 << 12)
        static let             pins = DiscordRateLimitURLParts(rawValue: 1 << 13)
        static let         webhooks = DiscordRateLimitURLParts(rawValue: 1 << 14)
        static let          members = DiscordRateLimitURLParts(rawValue: 1 << 15)
        static let           userID = DiscordRateLimitURLParts(rawValue: 1 << 16)
        static let            roles = DiscordRateLimitURLParts(rawValue: 1 << 17)
        static let           roleID = DiscordRateLimitURLParts(rawValue: 1 << 18)
        static let             bans = DiscordRateLimitURLParts(rawValue: 1 << 19)
        static let            users = DiscordRateLimitURLParts(rawValue: 1 << 20)
        static let        webhookID = DiscordRateLimitURLParts(rawValue: 1 << 21)
        static let     webhookToken = DiscordRateLimitURLParts(rawValue: 1 << 22)
        static let            slack = DiscordRateLimitURLParts(rawValue: 1 << 23)
        static let           github = DiscordRateLimitURLParts(rawValue: 1 << 24)
        static let         auditLog = DiscordRateLimitURLParts(rawValue: 1 << 25)
        static let        reactions = DiscordRateLimitURLParts(rawValue: 1 << 26)
        static let            emoji = DiscordRateLimitURLParts(rawValue: 1 << 27)
        static let           emojis = DiscordRateLimitURLParts(rawValue: 1 << 28)
        static let          emojiID = DiscordRateLimitURLParts(rawValue: 1 << 29)
        static let               me = DiscordRateLimitURLParts(rawValue: 1 << 30)
        static let     applications = DiscordRateLimitURLParts(rawValue: 1 << 31)
        static let    applicationID = DiscordRateLimitURLParts(rawValue: 1 << 32)
        static let         commands = DiscordRateLimitURLParts(rawValue: 1 << 33)
        static let        commandID = DiscordRateLimitURLParts(rawValue: 1 << 34)
        static let     interactions = DiscordRateLimitURLParts(rawValue: 1 << 35)
        static let    interactionID = DiscordRateLimitURLParts(rawValue: 1 << 36)
        static let interactionToken = DiscordRateLimitURLParts(rawValue: 1 << 37)
        static let         callback = DiscordRateLimitURLParts(rawValue: 1 << 38)
        static let          threads = DiscordRateLimitURLParts(rawValue: 1 << 39)
        static let    threadMembers = DiscordRateLimitURLParts(rawValue: 1 << 40)

        public init(rawValue: Int64) {
            self.rawValue = rawValue
        }
    }

    // MARK: Properties

    /// The guild or channel ID in this endpoint (or 0 if neither)
    /// There should never be a time when you need both the channel and guild id
    /// since every channel is bound to exactly one guild
    public let id: Snowflake

    /// The list of parts that the URL contains
    public let urlParts: DiscordRateLimitURLParts

    // MARK: Initializers

    /// Creates a new endpoint key.
    public init(id: Snowflake = 0, urlParts: DiscordRateLimitURLParts) {
        self.id = id
        self.urlParts = urlParts
    }

    /// Whether two keys are equal.
    public static func ==(lhs: DiscordRateLimitKey, rhs: DiscordRateLimitKey) -> Bool {
        return lhs.id == rhs.id && lhs.urlParts == rhs.urlParts
    }

    /// The hash of the key.
    public func hash(into hasher: inout Hasher) {
        hasher.combine(urlParts.rawValue)
        hasher.combine(id)
    }
}

/// A DiscordRateLimit's job is to keep track of a endpoint's rate limit.
/// If we told the DiscordRateLimiter we hit a limit, it will add the request to the Limit's queue.
/// Enqueued requests are handled through limit resets. Which are told to us by Discord in the x-ratelimit-reset header.
/// It's up to the DiscordRateLimiter to actually call the scheduleReset method.
private final class DiscordRateLimit {
    var limit: Double
    var remaining: Double
    var reset: Double
    var queue = [RateLimitedRequest]()

    private let endpointKey: DiscordRateLimitKey

    private var scheduledReset = false

    var atLimit: Bool {
        return remaining <= 0
    }

    private var deadlineForReset: DispatchTime {
        let seconds = reset - Date().timeIntervalSince1970

        guard seconds > 0 else { return DispatchTime(uptimeNanoseconds: 0) }

        return DispatchTime.now() + Double(seconds)
    }

    init(endpointKey: DiscordRateLimitKey, limit: Double, remaining: Double, reset: Double) {
        self.endpointKey = endpointKey
        self.limit = limit
        self.remaining = remaining
        self.reset = reset
    }

    func scheduleReset(on queue: DispatchQueue, with limiter: DiscordRateLimiter) {
        guard !scheduledReset else { return }

        scheduledReset = true

        queue.asyncAfter(deadline: deadlineForReset) {
            logger.debug("Reset triggered: \(self.endpointKey)")
            self.remaining = self.limit
            self.scheduledReset = false

            guard self.queue.count != 0 else { return }

            var removed = 0

            repeat {
                let limitedRequest = self.queue.removeFirst()

                limiter.executeRequest(limitedRequest.request, for: self.endpointKey, callback: limitedRequest.callback)

                removed += 1
            } while removed < Int(self.remaining) && self.queue.count != 0

            logger.debug("Sent \(removed) requests for limit: \(self.endpointKey)")
        }
    }

    func updateLimits(limit: Double, remaining: Double, reset: Double) {
        self.limit = limit
        self.remaining = remaining
        self.reset = reset
    }
}
