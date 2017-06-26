// The MIT License (MIT)
// Copyright (c) 2017 Erik Little

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

public extension DiscordEndpointConsumer where Self: DiscordUserActor {
    /// Default implementation
    public func createDM(with: String, callback: @escaping (DiscordDMChannel?) -> ()) {
        guard let contentData = JSON.encodeJSONData(["recipient_id": with]) else { return }

        let requestCallback: DiscordRequestCallback = { data, response, error in
            guard case let .object(channel)? = JSON.jsonFromResponse(data: data, response: response) else {
                callback(nil)
                return
            }
            callback(DiscordDMChannel(dmObject: channel))
        }
        rateLimiter.executeRequest(endpoint: .userChannels,
                                   token: token,
                                   requestInfo: .post(content: (contentData, type: .json)),
                                   callback: requestCallback)
    }

    /// Default implementation
    public func getDMs(callback: @escaping ([String: DiscordDMChannel]) -> ()) {
        let requestCallback: DiscordRequestCallback = { data, response, error in
            guard case let .array(channels)? = JSON.jsonFromResponse(data: data, response: response) else {
                callback([:])

                return
            }
            DefaultDiscordLogger.Logger.debug("Got DMChannels: \(channels)", type: "DiscordEndpointUser")
            callback(DiscordDMChannel.DMsfromArray(channels as! [[String: Any]]))
        }
        rateLimiter.executeRequest(endpoint: .userChannels,
                                   token: token,
                                   requestInfo: .get(params: nil),
                                   callback: requestCallback)
    }

    /// Default implementation
    public func getGuilds(callback: @escaping ([String: DiscordUserGuild]) -> ()) {
        let requestCallback: DiscordRequestCallback = {data, response, error in
            guard case let .array(guilds)? = JSON.jsonFromResponse(data: data, response: response) else {
                callback([:])

                return
            }

            callback(DiscordUserGuild.userGuildsFromArray(guilds as! [[String: Any]]))
        }
        rateLimiter.executeRequest(endpoint: .userGuilds,
                                   token: token,
                                   requestInfo: .get(params: nil),
                                   callback: requestCallback)
    }
}
