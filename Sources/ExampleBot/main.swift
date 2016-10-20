import Foundation
import SwiftDiscord

let queue = DispatchQueue(label: "Async Read")
let client = DiscordClient(token: "")

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

client.on("messageCreate") {data in
    guard let message = data[0] as? DiscordMessage else { return }

    let content = message.content

    guard content.hasPrefix("$") else { return }

    let commandArgs = String(content.characters.dropFirst()).components(separatedBy: " ")
    let command = commandArgs[0]

    if command == "swiftping" {
        client.sendMessage("pong", to: message.channelId)
    }
}

client.connect()

CFRunLoopRun()
