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
