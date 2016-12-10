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
#if os(macOS)
import ImageBrutalizer
#endif

typealias QueuedVideo = (link: String, channel: String)

class DiscordBot {
    let client: DiscordClient

    private var inVoiceChannel = false
    private var playingYoutube = false
    private var youtube = EncoderProcess()
    private var youtubeQueue = [QueuedVideo]()

    init(token: DiscordToken) {
        client = DiscordClient(token: token, configuration: [.log(.verbose)])

        attachHandlers()
    }

    func attachHandlers() {
        client.on("connect") {[weak self] data in
            guard let this = self else { return }

            print("Bot connected")

            print(this.client.getBotURL(with: [.sendMessages, .readMessages])!)
        }

        client.on("disconnect") {data in
            print("bot disconnected")
        }

        client.on("messageCreate") {[weak self] data in
            guard let this = self, let message = data[0] as? DiscordMessage else { return }

            this.handleMessage(message)
        }

        client.on("voiceEngine.ready") {[weak self] data in
            guard let this = self else { return }

            print("voice engine ready")

            this.inVoiceChannel = true
            this.playingYoutube = false

            guard !this.youtubeQueue.isEmpty else { return }

            let video = this.youtubeQueue.remove(at: 0)

            this.client.sendMessage("Playing \(video.link)", to: video.channel)

            _ = this.playYoutube(channelId: video.channel, link: video.link)
        }

        client.on("voiceEngine.disconnect") {[weak self] data in
            self?.inVoiceChannel = false
            self?.playingYoutube = false
        }
    }

    func brutalizeImage(options: [String], channelId: String) {
        #if os(macOS)
        let args = options.map(BrutalArg.init)
        var imagePath: String!

        loop: for arg in args {
            switch arg {
            case let .url(image):
                imagePath = image
                break loop
            default:
                continue
            }
        }

        guard imagePath != nil else {
            client.sendMessage("Missing image url", to: channelId)

            return
        }

        guard let request = createGetRequest(for: imagePath) else {
            client.sendMessage("Invalid url", to: channelId)

            return
        }

        getRequestData(for: request) {[weak self] data in
            guard let this = self else { return }
            guard let data = data else {
                this.client.sendMessage("Something went wrong with the request", to: channelId)

                return
            }

            guard let brutalizer = ImageBrutalizer(data: data) else {
                this.client.sendMessage("Invalid image", to: channelId)

                return
            }

            for arg in args {
                arg.brutalize(with: brutalizer)
            }

            guard let outputData = brutalizer.outputData else {
                this.client.sendMessage("Something went wrong brutalizing the image", to: channelId)

                return
            }

            this.client.sendFile(DiscordFileUpload(data: outputData, filename: "brutalized.png", mimeType: "image/png"),
                content: "Brutalized:", to: channelId)
        }
        #else
        client.sendMessage("Not available on Linux", to: channelId)
        #endif
    }

    func connect() {
        client.connect()
    }

    func disconnect() {
        client.disconnect()
    }

    private func findChannelFromName(_ name: String, in guild: DiscordGuild? = nil) -> DiscordGuildChannel? {
        // We have a guild to narrow the search
        if guild != nil, let channels = client.guilds[guild!.id]?.channels {
            return channels.filter({ $0.value.name == name }).map({ $0.1 }).first
        }

        // No guild, go through all the guilds
        // Returns first channel in the first guild with a match if multiple channels have the same name
        return client.guilds.flatMap({_, guild in
            return guild.channels.reduce(DiscordGuildChannel?.none, {cur, keyValue in
                guard cur == nil else { return cur } // already found

                return keyValue.value.name == name ? keyValue.value : nil
            })
        }).first
    }

    private func getRolesForUser(_ user: DiscordUser, on channelId: String) -> [DiscordRole] {
        for (_, guild) in client.guilds where guild.channels[channelId] != nil {
            guard let userInGuild = guild.members[user.id] else {
                print("This user doesn't seem to be in the guild?")

                return []
            }

            return guild.roles.filter({ userInGuild.roles.contains($0.key) }).map({ $0.1 })
        }

        return []
    }

    private func handleCommand(_ command: String, with arguments: [String], message: DiscordMessage) {
        print("got command \(command)")

        if command == "myroles" {
            let roles = getRolesForUser(message.author, on: message.channelId)

            client.sendMessage("Your roles: \(roles.map({ $0.name }))", to: message.channelId)
        } else if command == "yt", arguments.count == 1 {
            client.sendMessage(playYoutube(channelId: message.channelId, link: arguments[0]), to: message.channelId)
        } else if command == "join" && arguments.count == 1 {
            guard let channel = findChannelFromName(arguments[0], in: client.guildForChannel(message.channelId)) else {
                client.sendMessage("That doesn't look like a channel in this guild.",
                    to: message.channelId)

                return
            }

            guard channel.type == .voice else {
                client.sendMessage("That's not a voice channel.", to: message.channelId)

                return
            }

            client.joinVoiceChannel(channel.id)
        } else if command == "leave" {
            client.leaveVoiceChannel()
        } else if command == "skip" {
            if youtube.isRunning {
                youtube.terminate()
            }

            client.voiceEngine?.requestNewEncoder()
        } else if command == "brutal" {
            brutalizeImage(options: arguments, channelId: message.channelId)
        }
    }

    private func handleMessage(_ message: DiscordMessage) {
        guard message.content.hasPrefix("$") else { return }

        let commandArgs = String(message.content.characters.dropFirst()).components(separatedBy: " ")
        let command = commandArgs[0]

        handleCommand(command.lowercased(), with: Array(commandArgs.dropFirst()), message: message)
    }

    private func playYoutube(channelId: String, link: String) -> String {
        guard inVoiceChannel else { return "Not in voice channel" }
        guard !playingYoutube else {
            youtubeQueue.append((link, channelId))

            return "Video Queued. \(youtubeQueue.count) videos in queue"
        }

        playingYoutube = true

        youtube = EncoderProcess()
        youtube.launchPath = "/usr/local/bin/youtube-dl"
        youtube.arguments = ["-f", "bestaudio", "-q", "-o", "-", link]
        youtube.standardOutput = client.voiceEngine!.requestFileHandleForWriting()!

        youtube.terminationHandler = {[weak self] process in
            print("yt died")
            self?.client.voiceEngine?.encoder?.finishEncodingAndClose()
        }

        youtube.launch()

        return "Playing \(link)"
    }
}

private func createGetRequest(for string: String) -> URLRequest? {
    guard let url = URL(string: string) else { return nil }

    var request = URLRequest(url: url)

    request.httpMethod = "GET"

    return request
}

private func getRequestData(for request: URLRequest, callback: @escaping (Data?) -> Void) {
    URLSession.shared.dataTask(with: request) {data, response, error in
        guard data != nil, error == nil, let response = response as? HTTPURLResponse,
                response.statusCode == 200 else {
            callback(nil)

            return
        }

        callback(data!)
    }.resume()
}
