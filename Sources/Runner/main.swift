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

import CoreFoundation
import Foundation
import SwiftDiscord
import Dispatch

#if os(macOS)
let session = arc4random()
#else
let session = random()
#endif

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

var youtube: EncoderProcess!
var new = false

func handleQuit() {
    client.disconnect()
}

func handleTestGet() {
    client.getMessages(for: "232184444340011009", options: [.limit(3)]) {messages in
        print(messages)
    }
}

func handleJoin() {
    client.joinVoiceChannel(voiceChannel)
}

func handleLeave() {
    client.leaveVoiceChannel(voiceChannel)
}

func handlePlay() {
    new = false

    let music = FileHandle(forReadingAtPath: ("~/Music/testing.mp3" as NSString).expandingTildeInPath)!

    writeQueue.async {
        let data = music.readDataToEndOfFile()

        // print("read \(data)")
        client.voiceEngine?.send(data) {
            print("wrote all")

            guard !new else { return }

            print("requesting finish and close")

            client.voiceEngine?.encoder?.finishEncodingAndClose()
        }
    }
}

func handleNew() {
    new = true

    youtube?.terminate()
    client.voiceEngine?.requestNewEncoder()
}

func handleBot() {
    print(client.getBotURL(with: [.addReactions])!)
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

    permission.allow = DiscordPermission.readMessages | DiscordPermission.sendTTSMessages | DiscordPermission.sendMessages
    permission.deny = DiscordPermission.readMessageHistory.rawValue

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

func handleCreateInvite() {
    client.createInvite(for: "232184444340011009", options: [.maxUses(10), .maxAge(600)], callback: {invite in
        print(invite!)
    })
}

func handleGetInvites() {
    client.getInvites(for: "232184444340011009", callback: {invites in
        print(invites)
    })
}

func handleGetPins() {
    client.getPinnedMessages(for: "232184444340011009", callback: {messages in
        print(messages)
    })
}

func handleDeletePin() {
    client.deletePinnedMessage("237233947010924545", on: "232184444340011009")
}

func handleAddPin() {
    client.addPinnedMessage("236956932919787522", on: "232184444340011009")
}

func handleModifyChannel() {
    client.modifyChannel("232184444340011009", options: [.name("Testing_SwiftDiscord"), .topic("evan is dumb")])
}

func handleModifyGuild() {
    client.modifyGuild("201533018215677953", options: [.name("Evan's Pit")])
}

func handleGuildChannels() {
    client.getGuildChannels("186926276592795659") {channels in
        print(channels)
    }
}

func handleCreateChannel() {
    client.createGuildChannel(on: "201533018215677953", options: [.name("evan_is_dumb"), .type(.text),
        .permissionOverwrites([
            DiscordPermissionOverwrite(id: "194993070159298560", type: .member,
                allow: DiscordPermission.sendMessages | DiscordPermission.readMessages,
                deny: DiscordPermission.none.rawValue)
        ])])
}

func handlePosition() {
    client.modifyGuildChannelPosition(on: "201533018215677953", channelId: "237294069968142336", position: 0)
}

func handleGuilds() {
    print(client.guilds.count)
}

func handleGetMember() {
    client.getGuildMember(by: "229316633414336512", on: "186926276592795659") {member in
        print(member!)
    }
}

func handleGetMembers() {
    client.getGuildMembers(on: "186926276592795659", options: [.limit(500)]) {members in
        print(members)
    }
}

func handleBans() {
    client.getGuildBans(for: "232184444340011009") {bans in
        print(bans)
    }
}

func handleBan() {
    client.guildBan(userId: "225069761434746882", on: "201533018215677953")
}

func handleRemoveBan() {
    client.removeGuildBan(for: "225069761434746882", on: "201533018215677953")
}

func handleRoles() {
    client.getGuildRoles(for: "201533018215677953") {roles in
        print(roles)
    }
}

func handleCreateRole() {
    client.createGuildRole(on: "201533018215677953") {role in
        print(role!)
    }
}

func handleModifyRole() {
    var role = client.guilds["201533018215677953"]!.roles["240986482846859265"]!

    role.name = "evan"
    role.permissions = DiscordPermission.addReactions.rawValue

    client.modifyGuildRole(role, on: "201533018215677953")
}

func handleRemoveRole() {
    client.removeGuildRole("238074249133162496", on: "201533018215677953")
}

func handleAcceptInvite() {
    client.acceptInvite("somecode")
}

func handleGetInvite() {
    client.getInvite("somecode") {invite in
        print(invite!)
    }
}

func handleRequestAll() {
    client.requestAllUsers(on: "81384788765712384")
}

func handleCreateDM() {
    client.createDM(with: "104753987663712256") {channel in
        print(channel!)
    }
}

func handleGetDMs() {
    client.getDMs {dms in
        print(dms)
    }
}

func handleGetGuilds() {
    client.getGuilds {guilds in
        print(guilds)
    }
}

func handleClose() {
    exit(0)
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
    "bulkdelete": handleBulkDelete,
    "createinvite": handleCreateInvite,
    "getinvites": handleGetInvites,
    "getpins": handleGetPins,
    "deletepin": handleDeletePin,
    "addpin": handleAddPin,
    "modifychannel": handleModifyChannel,
    "modifyguild": handleModifyGuild,
    "guildchannels": handleGuildChannels,
    "createchannel": handleCreateChannel,
    "position": handlePosition,
    "guilds": handleGuilds,
    "getmember": handleGetMember,
    "getmembers": handleGetMembers,
    "bans": handleBans,
    "ban": handleBan,
    "removeban": handleRemoveBan,
    "roles": handleRoles,
    "createrole": handleCreateRole,
    "modifyrole": handleModifyRole,
    "removerole": handleRemoveRole,
    "acceptinvite": handleAcceptInvite,
    "getinvite": handleGetInvite,
    "requestall": handleRequestAll,
    "createdm": handleCreateDM,
    "getdms": handleGetDMs,
    "getguilds": handleGetGuilds,
    "close": handleClose,
]

func readAsync() {
	queue.async {
		guard let input = readLine(strippingNewline: true) else { return readAsync() }

        if let handler = handlers[input] {
            DispatchQueue.main.async {
                handler()
            }
        } else if input.hasPrefix("youtube") {
            let link = input.components(separatedBy: " ")[1]

            new = false
            youtube = EncoderProcess()
            youtube.launchPath = "/usr/local/bin/youtube-dl"
            youtube.arguments = ["-f", "bestaudio", "-q", "-o", "-", link]
            youtube.standardOutput = client.voiceEngine!.requestFileHandleForWriting()

            youtube.terminationHandler = {process in
                print("youtube-dl died")

                guard !new else { return }

                client.voiceEngine?.encoder?.finishEncodingAndClose()
            }

        	youtube.launch()
        } else if input.hasPrefix("game") {
            let game = input.components(separatedBy: " ").dropFirst().joined()

            client.setPresence([
                "idle_since": NSNull(),
                "game": [
                    "name": game,
                    "type": NSNull(),
                    "url": NSNull()
                ]
            ])
        } else if input.hasPrefix("guild") {
            let guildId = input.components(separatedBy: " ").dropFirst().first!

            print(client.guilds[guildId]!.members.count)
        } else {
        	client.sendMessage(input, to: textChannel)
        }

        readAsync()
	}
}

print("Type 'quit' to stop")
readAsync()

client.on("disconnect") {data in
	print("Engine died, exiting")
	// exit(0)
}

client.on("connect") {data in
	print("connect")
	// print(client.guilds)
}

client.on("guildCreate") {data in
    guard let guild = data[1] as? DiscordGuild else { fatalError("didn't get guild") }

    print("guild created \(guild.name)")
}

client.on("guildDelete") {data in
    print(data)
}

client.on("guildUpdate") {data in
    guard let guild = data[1] as? DiscordGuild else { return }
}

client.on("voiceEngine.disconnect") {data in
	print("voice engine closed")
}

client.on("voiceEngine.ready") {_ in
    print("voice engine is ready")
}

client.on("messageCreate") {data in
	guard let message = data[0] as? DiscordMessage else { fatalError("Didn't get message in message event") }

	// print(message)
}

client.on("channelCreate") {channel in
    print("channel created \(channel)")
}

client.on("channelDelete") {data in
    print(data)
}

client.onVoiceData = {voiceData in
    // print("Got voice data \(voiceData)")
}

client.connect()

CFRunLoopRun()
