import Foundation
import SwiftDiscord

// 201533018215677954 // pu
// 186926277276598273
// 201533008627499008 // meat
let voiceChannel = "201533018215677954"
// 186926276592795659
// 232184444340011009
let textChannel = "232184444340011009"
let queue = DispatchQueue(label: "Async Read")
let writeQueue = DispatchQueue(label: "Async Write")
let client = DiscordClient(token: "")

var writer: FileHandle!
var youtube: Process!

func handleQuit() {
    client.disconnect()
}

func handleTestGet() {
    client.getMessages(for: "232184444340011009", options: [.limit(3)]) {messages in
        print(messages)
    }
}

func handleJoin() {
    client.joinVoiceChannel(voiceChannel) {message in
        print(message)
    }
}

func handleLeave() {
    client.leaveVoiceChannel(voiceChannel)
}

func handlePlay() {
    let music = FileHandle(forReadingAtPath: "../../../Music/testing.mp3")!

    writeQueue.async {
        let data = music.readDataToEndOfFile()

        // print("read \(data)")
        client.voiceEngine?.send(data)
    }
}

func handleNew() {
    youtube?.terminate()
    client.voiceEngine?.requestNewEncoder()
}

func handleBot() {
    print(client.getBotURL(with: [.readMessages, .useVAD, .attachFiles]))
}

func handleChannel() {
    client.getChannel(textChannel) {channel in
        print(channel)
    }
}

let handlers = [
    "quit": handleQuit,
    "testget": handleTestGet,
    "join": handleJoin,
    "leave": handleLeave,
    "play": handlePlay,
    "new": handleNew,
    "bot": handleBot,
    "channel": handleChannel,
]

func readAsync() {
	queue.async {
		guard let input = readLine(strippingNewline: true) else { return readAsync() }

        if let handler = handlers[input] {
            handler()
        } else if input.hasPrefix("youtube") {
        	let link = input.components(separatedBy: " ")[1]
        	youtube = Process()

        	youtube.launchPath = "/usr/local/bin/youtube-dl"
        	youtube.arguments = ["-f", "bestaudio", "-q", "-o", "-", link]
        	youtube.standardOutput = writer

        	youtube.launch()
        } else if input.hasPrefix("message") {
        	client.sendMessage(input, to: textChannel)
        }

        readAsync()
	}
}

print("Type 'quit' to stop")
readAsync()

client.on("engine.disconnect") {data in
	print("Engine died, exiting")
	exit(0)
}

client.on("connect") {data in
	print("connect")
	// print(client.guilds)
}

client.on("voiceEngine.writeHandle") {data in
	guard let writeHandle = data[0] as? FileHandle else { fatalError("didn't get write handle") }

	print("Got handle")

	writer = writeHandle
}

client.on("voiceEngine.disconnect") {data in
	print("voice engine closed")
}

client.on("message") {data in
	guard let message = data[0] as? DiscordMessage else { fatalError("Didn't get message in message event") }

	// print(message)
}

client.connect()

CFRunLoopRun()