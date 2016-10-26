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

let queue = DispatchQueue(label: "Async Read")
let client = DiscordClient(token: "")

let voiceChannel = ""

var youtube: Process!

func readAsync() {
    queue.async {
        guard let input = readLine(strippingNewline: true) else { return readAsync() }

        if input == "quit" {
            client.disconnect()
        }

        readAsync()
    }
}

print("Type 'quit' to stop")
readAsync()

client.on("disconnect") {data in
    print("Engine died, exiting")
    exit(0)
}

client.on("connect") {data in
    let deadline = DispatchTime.now() + 3

    DispatchQueue.main.asyncAfter(deadline: deadline) {
        client.joinVoiceChannel(voiceChannel)
    }
}

client.on("voiceEngine.ready") {data in
    print("Voice engine ready")
}

client.on("messageCreate") {data in
    guard let message = data[0] as? DiscordMessage else { return }

    let content = message.content

    guard content.hasPrefix("$") else { return }

    let commandArgs = String(content.characters.dropFirst()).components(separatedBy: " ")
    let command = commandArgs[0]

    if command == "swiftping" {
        client.sendMessage("pong", to: message.channelId)
    } else if command == "youtube" {
        youtube = Process()
        youtube.launchPath = "/usr/local/bin/youtube-dl"
        youtube.arguments = ["-f", "bestaudio", "-q", "-o", "-", commandArgs.dropFirst().joined()]
        youtube.standardOutput = client.voiceEngine!.requestFileHandleForWriting()

        youtube.terminationHandler = {process in
            client.voiceEngine?.encoder?.finishEncodingAndClose()
        }

        youtube.launch()
    } else if command == "skip" {
        youtube.terminate()
        client.voiceEngine?.requestNewEncoder()
    }
}

client.connect()

CFRunLoopRun()
