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

/// Represents the Discord OAuth endpoint.
public enum DiscordOAuthEndpoint : String {
    /// The base OAuth endpoint.
    case baseURL = "https://discordapp.com/api/oauth2/authorize"
    /// The bot endpoint.
    case bot = "bot"

    // MARK: Methods

    private func createURL(getParams: [String: String]) -> URL {
        var params = getParams

        var com = URLComponents(url: URL(string: DiscordOAuthEndpoint.baseURL.rawValue)!,
            resolvingAgainstBaseURL: false)!

        params["scope"] = rawValue

        com.queryItems = params.map({ URLQueryItem(name: $0.key, value: $0.value) })

        return com.url!
    }

    /**
        Creates a url that can be used to authorize a bot.

        - parameter for: The snowflake id of the bot user
        - parameter with: An array of `DiscordPermission` that this bot should have
    */
    public static func createBotAddURL(for user: DiscordUser, with permissions: [DiscordPermission]) -> URL? {
        guard user.bot else { return nil }

        return DiscordOAuthEndpoint.bot.createURL(getParams: [
            "permissions": String(permissions.reduce(0, |)),
            "client_id": user.id
        ])
    }
}
