//
// Created by Erik Little on 3/25/17.
//

import Foundation
@testable import Discord

// IDs: Guild: 1xx, Channel: 2xx, User: 3xx, Role: 4xx, Emoji: 5xx, Message: 6xx

let helloPacket = "{\"t\":null,\"s\":null,\"op\":10,\"d\":{\"heartbeat_interval\":41250,\"_trace\":[\"discord-gateway-prd-1-24\"]}}"
let readyPacket = "{\"t\":\"READY\",\"s\":null,\"op\":0,\"d\":{\"session_id\": \"hello_world\"}}"

let testRole = DiscordRole(
    id: 400,
    color: 0,
    hoist: false,
    managed: false,
    mentionable: true,
    name: "My Test Role",
    permissions: [],
    position: 0
)

let testEmoji = DiscordEmoji(
    id: nil,
    managed: false,
    name: "500",
    roles: []
)

let testUser = DiscordUser(
    id: 42,
    bot: false,
    mfaEnabled: true,
    username: "TestUser",
    verified: true
)

let testMember = DiscordGuildMember(
    guildId: 100,
    user: testUser,
    deaf: false,
    mute: false,
    nick: "",
    roleIds: [400],
    joinedAt: Date()
)

let testGame = DiscordActivity(
    name: "testGame",
    type: .game
)

let testPresence = DiscordPresence(
    user: testUser,
    activities: [testGame],
    status: .offline,
    guildId: 100
)

let testGuildTextChannel = DiscordChannel(
    id: 200,
    type: .text,
    guildId: 100,
    position: 1,
    name: "test-text-channel"
)

let testGuildVoiceChannel = DiscordChannel(
    id: 202,
    type: .voice,
    guildId: 100,
    position: 5,
    name: "TestVoiceChannel",
    bitrate: 64_000
)

let testGuildChannelCategory = DiscordChannel(
    id: 203,
    type: .category,
    guildId: 100,
    position: 0,
    name: "TestCategory",
    parentId: 1
)

let testDMChannel = DiscordChannel(
    id: testUser.id,
    type: .dm,
    recipients: [testUser]
)

let testGroupDMChannel = DiscordChannel(
    id: testUser.id,
    type: .groupDM,
    name: "A group DM"
)

let testAttachment = DiscordAttachment(id: 0, filename: "test-attachment.txt")
let testEmbed = DiscordEmbed()

let testMessage = DiscordMessage(
    id: 600,
    type: .default,
    attachments: [testAttachment],
    author: testUser,
    channelId: testGuildTextChannel.id,
    content: "This is a test message",
    embeds: [testEmbed],
    timestamp: Date()
)

func createGuildMemberObjects(n: Int) -> [DiscordGuildMember] {
    var members: [DiscordGuildMember] = []

    for i in 0..<n {
        var user = testUser
        var member = testMember

        user.id = .init(UInt64(i))
        member.user = user

        members.append(member)
    }

    return members
}

func createPresenceObjects(n: Int) -> [DiscordPresence] {
    var presences: [DiscordPresence] = []

    for i in 0..<n {
        var user = testUser
        var presence = testPresence

        user.id = .init(UInt64(i))
        presence.user = user

        presences.append(presence)
    }

    return presences
}

func createEmojiObjects(n: Int) -> [DiscordEmoji] {
    var emojis: [DiscordEmoji] = []

    for i in 0..<n {
        var emoji = testEmoji

        emoji.id = .init("500\(i)")!
        emoji.name = "Custom emoji \(i)"

        emojis.append(emoji)
    }

    return emojis
}

let testGuild = DiscordGuild(
    id: 100,
    large: false,
    joinedAt: Date(),
    unavailable: false,
    members: .init(createGuildMemberObjects(n: 20)),
    channels: .init([testGuildTextChannel, testGuildVoiceChannel]),
    memberCount: 20,
    presences: .init(createPresenceObjects(n: 20)),
    name: "TestGuild"
)
