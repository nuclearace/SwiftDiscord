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

public extension DiscordEndpoint {
    // MARK: Users

    /**
        Creates a direct message channel with a user.

        - parameter with: The user that the channel will be opened with's snowflake id
        - parameter user: Our snowflake id
        - parameter with: The token to authenticate to Discord with
        - parameter callback: The callback function. Takes an optional `DiscordDMChannel`
    */
    public static func createDM(with: String, user: String, with token: DiscordToken,
            callback: @escaping (DiscordDMChannel?) -> Void) {
        guard let contentData = encodeJSON(["recipient_id": with])?.data(using: .utf8, allowLossyConversion: false)
                else {
            return
        }

        var request = createRequest(with: token, for: .userChannels, replacing: ["me": user])

        request.httpMethod = "POST"
        request.httpBody = contentData
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(String(contentData.count), forHTTPHeaderField: "Content-Length")

        let rateLimiterKey = DiscordRateLimitKey(endpoint: .userChannels, parameters: ["me": user])

        DiscordRateLimiter.executeRequest(request, for: rateLimiterKey, callback: {data, response, error in
            guard case let .object(channel)? = self.jsonFromResponse(data: data, response: response) else {
                callback(nil)

                return
            }

            callback(DiscordDMChannel(dmObject: channel))
        })
    }

    /**
        Gets the direct message channels for a user.

        - parameter user: Our snowflake id
        - parameter with: The token to authenticate to Discord with
        - parameter callback: The callback function, taking a dictionary of `DiscordDMChannel` associated by
                              the recipient's id
    */
    public static func getDMs(user: String, with token: DiscordToken,
            callback: @escaping ([String: DiscordDMChannel]) -> Void) {
        var request = createRequest(with: token, for: .userChannels, replacing: ["me": user])

        request.httpMethod = "GET"

        let rateLimiterKey = DiscordRateLimitKey(endpoint: .userChannels, parameters: ["me": user])

        DiscordRateLimiter.executeRequest(request, for: rateLimiterKey, callback: {data, response, error in
            guard case let .array(channels)? = self.jsonFromResponse(data: data, response: response) else {
                callback([:])

                return
            }

            DefaultDiscordLogger.Logger.debug("Got DMChannels: %@", type: "DiscordEndpointUser", args: channels)

            callback(DiscordDMChannel.DMsfromArray(channels as! [[String: Any]]))
        })
    }

    /**
        Gets guilds the user is in.

        - parameter user: Our snowflake id
        - parameter with: The token to authenticate to Discord with
        - parameter callback: The callback function, taking a dictionary of `DiscordUserGuild` associated by guild id
    */
    public static func getGuilds(user: String, with token: DiscordToken,
            callback: @escaping ([String: DiscordUserGuild]) -> Void) {
        var request = createRequest(with: token, for: .userGuilds, replacing: ["me": user])

        request.httpMethod = "GET"

        let rateLimiterKey = DiscordRateLimitKey(endpoint: .userGuilds, parameters: ["me": user])

        DiscordRateLimiter.executeRequest(request, for: rateLimiterKey, callback: {data, response, error in
            guard case let .array(guilds)? = self.jsonFromResponse(data: data, response: response) else {
                callback([:])

                return
            }

            callback(DiscordUserGuild.userGuildsFromArray(guilds as! [[String: Any]]))
        })
    }
}
