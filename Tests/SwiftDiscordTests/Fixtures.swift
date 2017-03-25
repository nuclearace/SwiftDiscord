//
// Created by Erik Little on 3/25/17.
//

import Foundation

let helloPacket = "{\"t\":null,\"s\":null,\"op\":10,\"d\":{\"heartbeat_interval\":41250,\"_trace\":[\"discord-gateway-prd-1-24\"]}}"
let readyPacket = "{\"t\":\"READY\",\"s\":null,\"op\":0,\"d\":{\"session_id\": \"hello_world\"}}"

let testRole: [String: Any] = [
    "color": 0,
    "hoist": false,
    "id": "testrole",
    "managed": false,
    "mentionable": true,
    "name": "My Test Role",
    "permissions": 0,
    "position": 0
]

let testUser: [String: Any] = [
    "avatar": "",
    "bot": false,
    "discriminator": "",
    "email": "",
    "id": "testuser",
    "mfa_enabled": false,
    "username": "TestUser",
    "verified": true
]

let testMember: [String: Any] = [
    "user": testUser,
    "deaf": false,
    "mute": false,
    "nick": "",
    "roles": ["testrole"],
    "joined_at": ""
]

let testGame: [String: Any] = [
    "name": "testGame",
    "type": 0,
    "url": ""
]

let testPresence: [String: Any] = [
    "guild_id": "testGuild",
    "user": testUser,
    "game": testGame,
    "nick": "",
    "status": "offline"
]

let testGuildChannel: [String: Any] = [
    "id": "guildChannel",
    "guild_id": "",
    "type": 0,
    "name": "",
    "permission_overwrites": [[String: Any]](),
    "position": 0
]

let testGuild: [String: Any] = [
    "channels": [[String: Any]](),
    "default_message_notifications": 0,
    "embed_enabled": false,
    "embed_channel_id": "",
    "emojis": [[String: Any]](),
    "features": [Any](),
    "icon": "",
    "id": "testGuild",
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
