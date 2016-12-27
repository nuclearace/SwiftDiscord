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

func createFormatMessage(withStats stats: [String: Any]) -> String {
    var statContent = ""

    let textChannels = stats["numberOfTextChannels"] as! Int
    let voiceChannels = stats["numberOfVoiceChannels"] as! Int

    statContent += "Name: \(stats["name"] as! String)\n------------------\n"
    statContent += "Number of guilds: \(stats["numberOfGuilds"] as! Int)\n\n"
    statContent += "Text channels: \(textChannels)\t\t\t\t\t"
    statContent += "Voice channels: \(voiceChannels)\n"
    statContent += "-------------------------------------------------------\n"
    statContent += "Total: \(textChannels + voiceChannels)\n\n"
    statContent += "Loaded Users: \(stats["numberOfLoadedUsers"] as! Int)\n"
    statContent += "Total Users: \(stats["totalNumberOfUsers"] as! Int)"

    if let memory = stats["memory"] as? Double {
        statContent += "\nMemory: \(memory) MB"
    }

    return "```${content}```".replacingOccurrences(of: "${content}", with: statContent)
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
