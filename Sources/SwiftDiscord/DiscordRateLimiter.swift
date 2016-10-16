import Foundation

/// The DiscordRateLimiter is in charge of making sure we don't flood Discord with requests.
/// It keeps a dictionary of DiscordRateLimitKeys and DiscordRateLimits.
/// All requests to the REST api should be routed through the DiscordRateLimiter.
/// If a DiscordRateLimit determines we have hit a limit, we add the request and its callback to the limit's queue
/// after that it is up to the DiscordRateLimit to decide when to make the request.
/// TODO handle the global rate limit
final class DiscordRateLimiter {
    static let shared = DiscordRateLimiter()

    private static var limitQueue = DispatchQueue(label: "limitQueue")

    private var endpointLimits = [DiscordRateLimitKey: DiscordRateLimit]()

    private init() {}

    static func executeRequest(_ request: URLRequest, for endpointKey: DiscordRateLimitKey,
            callback: @escaping (Data?, HTTPURLResponse?, Error?) -> Void) {
        limitQueue.async {
            if DiscordRateLimiter.shared.endpointLimits[endpointKey] == nil {
                // First time handling this endpoint, err on the side caution and limit to one
                DiscordRateLimiter.shared.endpointLimits[endpointKey] =
                    DiscordRateLimit(endpointKey: endpointKey, limit: 1, remaining: 1,
                        reset: Int(Date().timeIntervalSince1970) + 3)
            }

            let rateLimit = DiscordRateLimiter.shared.endpointLimits[endpointKey]!

            if rateLimit.atLimit {
                // We've hit a rate limit, enqueue this request for later
                rateLimit.queue.append(RateLimitedRequest(request: request, callback: callback))

                return
            }

            DiscordRateLimiter.shared.endpointLimits[endpointKey]?.remaining -= 1

            // print("doing request \(DiscordRateLimiter.shared.endpointLimits[endpointKey]?.remaining)")

            URLSession.shared.dataTask(with: request,
                completionHandler: handleResponse(endpointKey, callback)).resume()
        }
    }

    static func handleResponse(_ endpointKey: DiscordRateLimitKey, _ callback:
            @escaping (Data?, HTTPURLResponse?, Error?) -> Void) -> (Data?, URLResponse?, Error?) -> Void {
        return {data, response, error in
            limitQueue.async {
                guard error == nil else {
                    callback(nil, nil, error)

                    return
                }

                guard let response = response as? HTTPURLResponse else {
                    // Not quite sure what happened
                    callback(data, nil, error)

                    return
                }

                guard response.statusCode != 429 else {
                    // Hit rate limit
                    callback(data, response, error)

                    return
                }

                let rateLimit = DiscordRateLimiter.shared.endpointLimits[endpointKey]!

                if let limit = response.allHeaderFields["x-ratelimit-limit"] as? String,
                    let remaining = response.allHeaderFields["x-ratelimit-remaining"] as? String,
                    let reset = response.allHeaderFields["x-ratelimit-reset"] as? String {
                        // Update the limit and attempt to schedule a limit reset
                        rateLimit.updateLimits(limit: Int(limit)!, remaining: Int(remaining)!, reset: Int(reset)!)
                        rateLimit.scheduleReset(on: limitQueue)
                } else {
                    rateLimit.scheduleReset(on: limitQueue)
                }

                // print("new limit: \(DiscordRateLimiter.shared.endpointLimits[endpointKey]?.limit)")
                // print("new limit: \(DiscordRateLimiter.shared.endpointLimits[endpointKey]?.reset)")

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

private typealias RateLimitedRequest = (request: URLRequest, callback: (Data?, HTTPURLResponse?, Error?) -> Void)

/// A DiscordRateLimit's job is to keep track of a endpoint's rate limit.
/// If we told the DiscordRateLimiter we hit a limit, it will add the request to the Limit's queue.
/// Enqueued requests are handled through limit resets. Which are told to us by Discord in the x-ratelimit-reset header.
/// It's up to the DiscordRateLimiter to actually call the scheduleReset method.
private final class DiscordRateLimit {
    var endpointKey: DiscordRateLimitKey
    var limit: Int
    var remaining: Int
    var reset: Int
    var scheduledReset = false

    var queue = [RateLimitedRequest]()

    var atLimit: Bool {
        return remaining <= 0
    }

    var deadlineForReset: DispatchTime {
        let seconds = reset - Int(Date().timeIntervalSince1970)

        guard seconds > 0 else { return DispatchTime(uptimeNanoseconds: 0) }

        // print("seconds till reset: \(seconds)")

        return DispatchTime.now() + Double(UInt64(seconds) * NSEC_PER_SEC) / Double(NSEC_PER_SEC)
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
            // print("reset triggered")
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

            // print("sent \(removed) requests")
        }
    }

    func updateLimits(limit: Int, remaining: Int, reset: Int) {
        self.limit = limit
        self.remaining = remaining
        self.reset = reset
    }
}
