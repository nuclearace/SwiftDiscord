import Foundation

public extension DiscordEndpoint {
    public static func acceptInvite(_ invite: String, with token: String, isBot bot: Bool) {
        var request = createRequest(with: token, for: .invites, replacing: [
            "invite.code": invite,
            ], isBot: bot)

        request.httpMethod = "POST"

        print(request)

        let rateLimiterKey = DiscordRateLimitKey(endpoint: .invites, parameters: ["invite.code": invite])

        DiscordRateLimiter.executeRequest(request, for: rateLimiterKey, callback: {data, response, error in })
    }

    public static func getInvite(_ invite: String, with token: String, isBot bot: Bool,
            callback: @escaping (DiscordInvite?) -> Void) {
        var request = createRequest(with: token, for: .invites, replacing: [
            "invite.code": invite,
            ], isBot: bot)

        request.httpMethod = "GET"

        let rateLimiterKey = DiscordRateLimitKey(endpoint: .invites, parameters: ["invite.code": invite])

        DiscordRateLimiter.executeRequest(request, for: rateLimiterKey, callback: {data, response, error in
            guard let data = data, response?.statusCode == 200 else {
                callback(nil)

                return
            }

            guard let stringData = String(data: data, encoding: .utf8), let json = decodeJSON(stringData),
                case let .dictionary(invite) = json else {
                    callback(nil)

                    return
            }

            callback(DiscordInvite(inviteObject: invite))
        })
    }
}
