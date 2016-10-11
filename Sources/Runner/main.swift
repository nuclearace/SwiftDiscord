import Foundation
import SwiftDiscord

let queue = DispatchQueue(label: "Async Read")
let client = DiscordClient(token: "")

func readAsync() {
	queue.async {
		guard let input = readLine(strippingNewline: true) else { return readAsync() }

        if input == "quit" {
            client.disconnect()
        } else if input == "testget" {
        	client.getMessages(for: "232184444340011009", options: [.limit(3)]) {messages in
        		print(messages)
        	}
        } else if input == "joinvoice" {
        	client.joinVoiceChannel("201533018215677954") {message in
        		print(message)
        	}
        } else if input.hasPrefix("play") {
        	let pipe = Pipe()
        	let process = Process()
        	let readHandle = pipe.fileHandleForReading

        	process.launchPath = "/usr/local/bin/ffmpeg"
        	process.standardInput = FileHandle.nullDevice
        	process.standardOutput = pipe
        	process.arguments = ["-hide_banner", "-i", "../../../Music/testing.mp3", "-f", "data", "-map", "0:a", "-ar", 
        		"48000", "-ac", "2", "-acodec", "libopus", "-sample_fmt", "s16", "-vbr", "off", "-b:a", "128000", 
        		"-compression_level", "10", "pipe:1"]

        	process.launch()

        	client.voiceEngine?.sendVoiceData(readHandle.readDataToEndOfFile())
        } else {
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

client.on("message") {data in
	guard let message = data[0] as? DiscordMessage else { fatalError("Didn't get message in message event") }

	print(message)
}

client.connect()

CFRunLoopRun()