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
import SwiftDiscord

func createFormatMessage(withStats stats: [String: Any]) -> DiscordEmbed {
    let guilds = stats["numberOfGuilds"] as! Int
    let textChannels = stats["numberOfTextChannels"] as! Int
    let voiceChannels = stats["numberOfVoiceChannels"] as! Int
    let numberOfLoadedUsers = stats["numberOfLoadedUsers"] as! Int
    let totalNumberOfUsers = stats["totalNumberOfUsers"] as! Int
    let shards = stats["shards"] as! Int
    let fieldMaker = DiscordEmbed.Field.init(name:value:inline:)

    var embed = DiscordEmbed(title: "\(stats["name"] as! String)'s stats",
                             description: "[Source](\(sourceUrl.absoluteString))",
                             author: DiscordEmbed.Author(name: "nuclearace",
                                                         iconUrl: authorImage,
                                                         url: authorUrl),
                             color: 0xF07F07)

    embed.fields.append(fieldMaker("Guilds", String(guilds), false))
    embed.fields.append(fieldMaker("Text Channels", String(textChannels), true))
    embed.fields.append(fieldMaker("Voice Channels", String(voiceChannels), true))
    embed.fields.append(fieldMaker("Total Channels", String(voiceChannels + textChannels), true))
    embed.fields.append(fieldMaker("Loaded Users", String(numberOfLoadedUsers), true))
    embed.fields.append(fieldMaker("Total Users", String(totalNumberOfUsers), true))
    embed.fields.append(fieldMaker("Shards", String(shards), true))

    if let memory = stats["memory"] as? Double {
        embed.fields.append(fieldMaker("Memory", "\(memory) MB", true))
    }

    return embed
}

func createGetRequest(for string: String) -> URLRequest? {
    guard let url = URL(string: string) else { return nil }

    var request = URLRequest(url: url)

    request.httpMethod = "GET"

    return request
}

func getRequestData(for request: URLRequest, callback: @escaping (Data?) -> Void) {
    URLSession.shared.dataTask(with: request) {data, response, error in
        guard data != nil, error == nil, let response = response as? HTTPURLResponse,
                response.statusCode == 200 else {
            callback(nil)

            return
        }

        callback(data!)
    }.resume()
}
