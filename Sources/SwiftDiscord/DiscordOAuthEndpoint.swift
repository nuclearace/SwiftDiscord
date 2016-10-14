import Foundation

public enum DiscordOAuthEndpoint : String {
    case baseURL = "https://discordapp.com/api/oauth2/authorize"
    case bot = "bot"

    private func createURL(getParams: [String: String]) -> URL {
        var params = getParams

        var com = URLComponents(url: URL(string: DiscordOAuthEndpoint.baseURL.rawValue)!,
            resolvingAgainstBaseURL: false)!

        params["scope"] = rawValue

        com.queryItems = params.map({ URLQueryItem(name: $0.key, value: $0.value) })

        return com.url!
    }

    public static func createBotAddURL(for user: DiscordUser, with permissions: [DiscordPermission]) -> URL? {
        guard user.bot else { return nil }

        return DiscordOAuthEndpoint.bot.createURL(getParams: [
                "permissions": String(permissions.reduce(0, |)),
                "client_id": user.id
            ])
    }
}
