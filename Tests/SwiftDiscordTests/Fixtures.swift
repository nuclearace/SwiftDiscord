//
// Created by Erik Little on 3/25/17.
//

import Foundation

// IDs: Guild: 1xx, Channel: 2xx, User: 3xx, Role: 4xx, Emoji: 5xx, Message: 6xx

let helloPacket = "{\"t\":null,\"s\":null,\"op\":10,\"d\":{\"heartbeat_interval\":41250,\"_trace\":[\"discord-gateway-prd-1-24\"]}}"
let readyPacket = "{\"t\":\"READY\",\"s\":null,\"op\":0,\"d\":{\"session_id\": \"hello_world\"}}"

let testRole: [String: Any] = [
    "color": 0,
    "hoist": false,
    "id": "400",
    "managed": false,
    "mentionable": true,
    "name": "My Test Role",
    "permissions": "0",
    "position": 0
]

let testEmoji: [String: Any] = [
    "id": "testEmoji",
    "managed": false,
    "name": "500",
    "require_colons": true,
    "roles": [] as [String]
]

let testUser: [String: Any] = [
    "avatar": "",
    "bot": false,
    "discriminator": "",
    "email": "",
    "id": "300",
    "mfa_enabled": false,
    "username": "TestUser",
    "verified": true
]

let testMember: [String: Any] = [
    "user": testUser,
    "deaf": false,
    "mute": false,
    "nick": "",
    "roles": ["400"],
    "joined_at": ""
]

let testGame: [String: Any] = [
    "name": "testGame",
    "type": 0,
    "url": ""
]

let testPresence: [String: Any] = [
    "guild_id": "100",
    "user": testUser,
    "game": testGame,
    "nick": "",
    "status": "offline"
]

let testGuildTextChannel: [String: Any] = [
    "id": "200",
    "guild_id": "100",
    "type": 0,
    "name": "TestTextChannel",
    "permission_overwrites": [[String: Any]](),
    "position": 0
]

let testGuildVoiceChannel: [String: Any] = [
    "id": "202",
    "guild_id": "testGuild",
    "type": 2,
    "name": "TestVoiceChannel",
    "is_private": false,
    "permission_overwrites": [[String: Any]](),
    "position": 5,
    "bitrate": 64000
]

let testGuildChannelCategory: [String: Any] = [
    "id": "203",
    "guild_id": "100",
    "type": 4,
    "parent_id": -1,
    "name": "TestCategory",
    "permission_overwrites": [[String: Any]](),
    "position": 0
]

let testGuild: [String: Any] = [
    "channels": [[String: Any]](),
    "default_message_notifications": 0,
    "widget_enabled": false,
    "widget_channel_id": "",
    "emojis": [[String: Any]](),
    "features": [Any](),
    "icon": "",
    "id": "100",
    "large": false,
    "member_count": 0,
    "mfa_level": 0,
    "name": "Test Guild",
    "owner_id": "",
    "presences": [[String: Any]](),
    "region": "",
    "roles": [[String: Any]](),
    "splash": "",
    "verification_level": 0,
    "voice_states": [[String: Any]](),
    "unavailable": false,
    "joined_at": "",
    "members": [[String: Any]]()
]

let testDMChannel: [String: Any] = [
    "type": 1,
    "recipients": [testUser],
    "id": testUser["id"] as! String,
    "last_message_id": ""
]

let testGroupDMChannel: [String: Any] = [
    "type": 3,
    "recipients": [testUser],
    "id": testUser["id"] as! String,
    "last_message_id": "",
    "name": "A Group DM"
]

let testAttachment: [String: Any] = [:]
let testEmbed: [String: Any] = [:]

let testMessage: [String: Any] = [
    "attachments": [testAttachment],
    "author": testUser,
    "channel_id": testGuildTextChannel["id"] as! String,
    "content": "This is a test message",
    "embeds": [testEmbed],
    "id": "600",
    "mention_everyone": false,
    "mention_roles": [String](),
    "mentions": [[String: Any]](),
    "nonce": "",
    "pinned": false,
    "reactions": [[String: Any]](),
    "tts": false,
    "edited_timestamp": "",
    "timestamp": ""
]

func createGuildMemberObjects(n: Int) -> [[String: Any]] {
    var members = [[String: Any]]()

    for i in 0..<n {
        var user = testUser
        var member = testMember

        user["id"] = String(i)
        member["user"] = user

        members.append(member)
    }

    return members
}

func createPresenceObjects(n: Int) -> [[String: Any]] {
    var presences = [[String: Any]]()

    for i in 0..<n {
        var user = testUser
        var presence = testPresence

        user["id"] = String(i)
        presence["user"] = user

        presences.append(presence)
    }

    return presences
}

func createEmojiObjects(n: Int) -> [[String: Any]] {
    var emojis = [[String: Any]]()

    for i in 0..<n {
        var emoji = testUser

        emoji["id"] = String("500\(i)")
        emoji["name"] = String("Custom emoji \(i)")

        emojis.append(emoji)
    }

    return emojis
}

let testGuildJSON: [String: Any] = {
    var tGuild = testGuild

    tGuild["channels"] = [testGuildTextChannel, testGuildVoiceChannel]
    tGuild["members"] = createGuildMemberObjects(n: 20)
    tGuild["presences"] = createPresenceObjects(n: 20)
    tGuild["member_count"] = 20

    return tGuild
}()
