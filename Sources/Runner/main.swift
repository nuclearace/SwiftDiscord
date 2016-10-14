import Foundation
import SwiftDiscord

let queue = DispatchQueue(label: "Async Read")
let writeQueue = DispatchQueue(label: "Async Write")
let client = DiscordClient(token: "")

var writer: FileHandle!
var youtube: Process!

func readAsync() {
	queue.async {
		guard let input = readLine(strippingNewline: true) else { return readAsync() }

        if input == "quit" {
            client.disconnect()
        } else if input == "testget" {
        	client.getMessages(for: "232184444340011009", options: [.limit(3)]) {messages in
        		print(messages)
        	}
        } else if input == "join" {
        	// 201533018215677954 // pu
        	// 186926277276598273
        	// 201533008627499008 // meat
        	client.joinVoiceChannel("201533018215677954") {message in
        		print(message)
        	}
        } else if input == "leave" {
        	client.leaveVoiceChannel("201533018215677954")
        } else if input == "play" {
        	let music = FileHandle(forReadingAtPath: "../../Music/testing.mp3")!

        	writeQueue.async {
        		let data = music.readDataToEndOfFile()

        		// print("read \(data)")
        		client.voiceEngine?.send(data)
        	}
        	// client.voiceEngine?.sendVoiceData(music.readDataToEndOfFile())
        } else if input == "new" {
            // writer.closeFile()3072
            youtube?.terminate()
            client.voiceEngine?.requestNewEncoder()
        } else if input.hasPrefix("youtube") {
        	let link = input.components(separatedBy: " ")[1]
        	youtube = Process()

        	youtube.launchPath = "/usr/local/bin/youtube-dl"
        	youtube.arguments = ["-f", "bestaudio", "-q", "-o", "-", link]
        	youtube.standardOutput = writer

        	youtube.launch()
        } else if input == "silence" {
            // client.voiceEngine?.sendVoiceData(Data(bytes: [0xF8, 0xFF, 0xFE, 0xF8, 0xFF, 0xFE, 0xF8, 0xFF, 0xFE,
            //     0xF8, 0xFF, 0xFE, 0xF8, 0xFF, 0xFE]))
        } else {
        	// 186926276592795659
        	// 232184444340011009
        	client.sendMessage(input, to: "232184444340011009")
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