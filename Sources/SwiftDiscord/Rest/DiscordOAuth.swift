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

/// Represents the Discord OAuth endpoint and the different scopes Disocrd has.
public enum DiscordOAuthEndpoint : String {
    /// The base OAuth endpoint.
    case baseURL = "https://discord.com/api/oauth2/authorize"

    /// The bot scope.
    case bot

    /// allows /users/@me/connections to return linked Twitch and YouTube accounts.
    case connections

    /// Enables /users/@me to return an email.
    case email

    /// Allows /users/@me without email.
    case identify

    /// Allows /users/@me/guilds to return basic information about all of a user's guilds.
    case guilds

    /// Allows /invites/{invite.id} to be used for joining a user's guild.
    case guildsJoin = "guilds.join"

    /// Allows your app to join users to a group dm.
    case gdmJoin = "gdm.join"

    /// For local rpc server api access, this allows you to read messages from all client channels
    /// (otherwise restricted to channels/guilds your app creates).
    case messagesRead = "messages.read"

    /// For local rpc server access, this allows you to control a user's local Discord client.
    case rpc

    /// For local rpc server api access, this allows you to access the API as the local user.
    case rpcApi = "rpc.api"

    /// For local rpc server api access, this allows you to receive notifications pushed out to the user.
    case rpcNotificationsRead = "rpc.notifications.read"

    /// This generates a webhook that is returned in the oauth token response for authorization code grants.
    case webhookIncoming = "webhook.incoming"

    // MARK: Methods

    private func createURL(getParams: [String: String]) -> URL {
        var params = getParams
        var com = URLComponents(url: URL(string: DiscordOAuthEndpoint.baseURL.rawValue)!,
                                resolvingAgainstBaseURL: false)!

        params["scope"] = rawValue

        com.queryItems = params.map({ URLQueryItem(name: $0.key, value: $0.value) })

        return com.url!
    }

    ///
    /// Creates a url that can be used to authorize a bot.
    ///
    /// - parameter for: The snowflake id of the bot user
    /// - parameter with: An array of `DiscordPermission` that this bot should have
    ///
    public static func createBotAddURL(for user: DiscordUser, with permissions: DiscordPermission) -> URL? {
        guard user.bot else { return nil }

        return DiscordOAuthEndpoint.bot.createURL(getParams: [
            "permissions": permissions.rawValue.description,
            "client_id": user.id.description
        ])
    }
}
