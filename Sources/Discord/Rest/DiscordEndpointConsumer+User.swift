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
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import Logging

fileprivate let logger = Logger(label: "DiscordEndpointUser")

public extension DiscordEndpointConsumer where Self: DiscordUserActor {
    /// Default implementation
    func createDM(with: UserID,
                         callback: @escaping (DiscordDMChannel?, HTTPURLResponse?) -> ()) {
        guard let contentData = JSON.encodeJSONData(["recipient_id": with]) else { return }

        let requestCallback: DiscordRequestCallback = { data, response, error in
            guard case let .object(channel)? = JSON.jsonFromResponse(data: data, response: response) else {
                callback(nil, response)

                return
            }

            callback(DiscordDMChannel(dmObject: channel), response)
        }

        rateLimiter.executeRequest(endpoint: .userChannels,
                                   token: token,
                                   requestInfo: .post(content: .json(contentData), extraHeaders: nil),
                                   callback: requestCallback)
    }

    /// Default implementation
    func getDMs(callback: @escaping ([ChannelID: DiscordDMChannel], HTTPURLResponse?) -> ()) {
        let requestCallback: DiscordRequestCallback = { data, response, error in
            guard case let .array(channels)? = JSON.jsonFromResponse(data: data, response: response) else {
                callback([:], response)

                return
            }

            logger.debug("Got DMChannels: \(channels)")
            callback(DiscordDMChannel.DMsfromArray(channels as! [[String: Any]]), response)
        }

        rateLimiter.executeRequest(endpoint: .userChannels,
                                   token: token,
                                   requestInfo: .get(params: nil, extraHeaders: nil),
                                   callback: requestCallback)
    }

    /// Default implementation
    func getGuilds(callback: @escaping ([GuildID: DiscordUserGuild], HTTPURLResponse?) -> ()) {
        let requestCallback: DiscordRequestCallback = {data, response, error in
            guard case let .array(guilds)? = JSON.jsonFromResponse(data: data, response: response) else {
                callback([:], response)

                return
            }

            callback(DiscordUserGuild.userGuildsFromArray(guilds as! [[String: Any]]), response)
        }

        rateLimiter.executeRequest(endpoint: .userGuilds,
                                   token: token,
                                   requestInfo: .get(params: nil, extraHeaders: nil),
                                   callback: requestCallback)
    }
}
