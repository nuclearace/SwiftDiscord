//
// Created by Erik Little on 3/25/17.
//

import Foundation

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
