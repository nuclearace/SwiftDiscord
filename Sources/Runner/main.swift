import Foundation
import SwiftDiscord

let session = arc4random()

// 201533018215677954 // pu
// 186926277276598273
// 201533008627499008 // meat
let voiceChannel = "186926277276598273"
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
    print(client.getBotURL(with: [.readMessages, .useVAD, .attachFiles])!)
}

func handleChannel() {
    client.getChannel(textChannel) {channel in
        print(channel!)
    }
}

func handleTestLimit() {
    for i in 0..<100 {
        client.sendMessage("\(session): \(i)", to: textChannel)
    }

    for i in 0..<100 {
        client.sendMessage("\(session): \(i)", to: "236929907169427458")
    }
}

func handleTyping() {
    client.triggerTyping(on: textChannel)
}

func handleDeletePermission() {
    client.deleteChannelPermission("194993070159298560", on: "232184444340011009")
}

func handleEditPermission() {
    var permission = client.guilds["201533018215677953"]!.channels["232184444340011009"]!.permissionOverwrites["194993070159298560"]!

    permission.allow = DiscordPermission.readMessages | DiscordPermission.sendTTSMessages
    permission.deny = DiscordPermission.sendMessages | DiscordPermission.readMessageHistory

    client.editChannelPermission(permission, on: "232184444340011009")
}

func handleDeleteChannel() {
    client.deleteChannel("236929907169427458")
}

func handleDeleteMessage() {
    client.deleteMessage("236999881917595648", on: "232184444340011009")
}

func handleEditMessage() {
    client.editMessage("236956932919787522", on: "232184444340011009", content: "Way Down We Go")
}

func handleBulkDelete() {
    client.bulkDeleteMessages(["236956795514519552", "236956849004478464"], on: "232184444340011009")
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
    "testlimit": handleTestLimit,
    "typing": handleTyping,
    "deletepermission": handleDeletePermission,
    "editpermission": handleEditPermission,
    "deletechannel": handleDeleteChannel,
    "deletemessage": handleDeleteMessage,
    "editmessage": handleEditMessage,
    "bulkdelete": handleBulkDelete
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
        } else {
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