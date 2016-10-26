import Foundation

public extension DiscordEndpoint {
    public static func createDM(with: String, user: String, with token: String, isBot bot: Bool,
            callback: @escaping (DiscordDMChannel?) -> Void) {

        guard let contentData = encodeJSON(["recipient_id": with])?.data(using: .utf8, allowLossyConversion: false)
                else {
            return
        }

        var request = createRequest(with: token, for: .userChannels, replacing: ["me": user], isBot: bot)

        request.httpMethod = "POST"
        request.httpBody = contentData
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(String(contentData.count), forHTTPHeaderField: "Content-Length")

        let rateLimiterKey = DiscordRateLimitKey(endpoint: .userChannels, parameters: ["me": user])

        DiscordRateLimiter.executeRequest(request, for: rateLimiterKey, callback: {data, response, error in
            guard let data = data, response?.statusCode == 200 else {
                callback(nil)

                return
            }

            guard let stringData = String(data: data, encoding: .utf8), let json = decodeJSON(stringData),
                case let .dictionary(channel) = json else {
                    callback(nil)

                    return
            }

            callback(DiscordDMChannel(dmObject: channel))
        })
    }

    public static func getDMs(user: String, with token: String, isBot bot: Bool,
            callback: @escaping ([String: DiscordDMChannel]) -> Void) {
        var request = createRequest(with: token, for: .userChannels, replacing: ["me": user], isBot: bot)

        request.httpMethod = "GET"

        let rateLimiterKey = DiscordRateLimitKey(endpoint: .userChannels, parameters: ["me": user])

        DiscordRateLimiter.executeRequest(request, for: rateLimiterKey, callback: {data, response, error in
            guard let data = data, response?.statusCode == 200 else {
                callback([:])

                return
            }

            guard let stringData = String(data: data, encoding: .utf8), let json = decodeJSON(stringData),
                case let .array(channels) = json else {
                    callback([:])

                    return
            }

            callback(DiscordDMChannel.DMsfromArray(channels as! [[String: Any]]))
        })
    }
}
