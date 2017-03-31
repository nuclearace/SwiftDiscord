//
// Created by Erik Little on 3/26/17.
//

import Foundation
import XCTest
@testable import SwiftDiscord

class TestDiscordClient : XCTestCase {
    func testClientCreatesGuild() {
        expectations[.guildCreate] = expectation(description: "Client should call guild create method")

        client.handleDispatch(event: .guildCreate, data: .object(testGuildJSON))

        waitForExpectations(timeout: 0.2)
    }

    func testClientUpdatesGuild() {
        expectations[.guildCreate] = expectation(description: "Client should call guild create method")
        expectations[.guildUpdate] = expectation(description: "Client should call guild update method")

        let updateJSON: [String: Any] = [
            "id": "testGuild",
            "name": "A new name"
        ]

        client.handleDispatch(event: .guildCreate, data: .object(testGuildJSON))
        client.handleDispatch(event: .guildUpdate, data: .object(updateJSON))

        waitForExpectations(timeout: 0.2)
    }

    func testClientDeletesGuild() {
        expectations[.guildCreate] = expectation(description: "Client should call guild create method")
        expectations[.guildDelete] = expectation(description: "Client should call guild delete method")

        client.handleDispatch(event: .guildCreate, data: .object(testGuildJSON))
        client.handleDispatch(event: .guildDelete, data: .object(["id": "testGuild"]))

        waitForExpectations(timeout: 0.2)
    }

    func testClientHandlesGuildMemberAdd() {
        expectations[.guildCreate] = expectation(description: "Client should call guild create method")
        expectations[.guildMemberAdd] = expectation(description: "Client should call guild member add method")

        var tMember = testMember
        var tUser = testUser

        tUser["id"] = "30"
        tMember["guild_id"] = "testGuild"
        tMember["user"] = tUser
        tMember["nick"] = "test nick"

        client.handleDispatch(event: .guildCreate, data: .object(testGuildJSON))
        client.handleDispatch(event: .guildMemberAdd, data: .object(tMember))

        waitForExpectations(timeout: 0.2)
    }

    func testClientHandlesGuildMemberUpdate() {
        expectations[.guildCreate] = expectation(description: "Client should call guild member update method")
        expectations[.guildMemberUpdate] = expectation(description: "Client should call guild member update method")

        var tMember = testMember
        var tUser = testUser

        tUser["id"] = "15"
        tMember["guild_id"] = "testGuild"
        tMember["user"] = tUser
        tMember["nick"] = "a new nick"

        client.handleDispatch(event: .guildCreate, data: .object(testGuildJSON))
        client.handleDispatch(event: .guildMemberUpdate, data: .object(tMember))

        waitForExpectations(timeout: 0.2)
    }

    func testClientHandlesGuildMemberRemove() {
        expectations[.guildCreate] = expectation(description: "Client should call guild member remove method")
        expectations[.guildMemberRemove] = expectation(description: "Client should call guild member remove method")

        var tMember = testMember
        var tUser = testUser

        tUser["id"] = "15"
        tMember["guild_id"] = "testGuild"
        tMember["user"] = tUser

        client.handleDispatch(event: .guildCreate, data: .object(testGuildJSON))
        client.handleDispatch(event: .guildMemberRemove, data: .object(tMember))

        waitForExpectations(timeout: 0.2)
    }

    func testClientCreatesGuildChannel() {
        expectations[.guildCreate] = expectation(description: "Client should call guild member remove method")
        expectations[.channelCreate] = expectation(description: "Client should call create create method")

        var tChannel = testGuildChannel

        tChannel["id"] = "testChannel2"
        tChannel["name"] = "A new channel"

        client.handleDispatch(event: .guildCreate, data: .object(testGuildJSON))
        client.handleDispatch(event: .channelCreate, data: .object(tChannel))

        waitForExpectations(timeout: 0.2)
    }

    func testClientCreatesDMChannel() {
        expectations[.channelCreate] = expectation(description: "Client should call create create method")

        client.handleDispatch(event: .channelCreate, data: .object(testDMChannel))

        waitForExpectations(timeout: 0.2)
    }

    func PENDING_testClientCreatesGroupDMChannel() { /* TODO write test */ }

    func testClientHandlesGuildEmojiUpdate() {
        expectations[.guildCreate] = expectation(description: "Client should call guild member remove method")
        expectations[.guildEmojisUpdate] = expectation(description: "Client should call guild emoji update method")

        let emojiUpdate: [String: Any] = [
            "guild_id": "testGuild",
            "emojis": createEmojiObjects(n: 20)
        ]

        client.handleDispatch(event: .guildCreate, data: .object(testGuildJSON))
        client.handleDispatch(event: .guildEmojisUpdate, data: .object(emojiUpdate))

        waitForExpectations(timeout: 0.2)
    }

    func testClientHandlesRoleCreate() {
        expectations[.guildCreate] = expectation(description: "Client should call guild member remove method")
        expectations[.guildRoleCreate] = expectation(description: "Client should call guild role create method")

        let roleCreate: [String: Any] = [
            "guild_id": "testGuild",
            "role": testRole
        ]

        client.handleDispatch(event: .guildCreate, data: .object(testGuildJSON))
        client.handleDispatch(event: .guildRoleCreate, data: .object(roleCreate))

        waitForExpectations(timeout: 0.2)
    }

    func testClientHandlesRoleUpdate() {
        expectations[.guildCreate] = expectation(description: "Client should call guild member remove method")
        expectations[.guildRoleCreate] = expectation(description: "Client should call guild role create method")
        expectations[.guildRoleUpdate] = expectation(description: "Client should call guild role update method")

        var tRole = testRole
        var roleUpdate: [String: Any] = [
            "guild_id": "testGuild",
            "role": testRole
        ]

        client.handleDispatch(event: .guildCreate, data: .object(testGuildJSON))
        client.handleDispatch(event: .guildRoleCreate, data: .object(roleUpdate))

        tRole["name"] = "A dank role"
        roleUpdate["role"] = tRole

        client.handleDispatch(event: .guildRoleUpdate, data: .object(roleUpdate))

        waitForExpectations(timeout: 0.2)
    }

    func testClientHandlesRoleRemove() {
        expectations[.guildCreate] = expectation(description: "Client should call guild member remove method")
        expectations[.guildRoleCreate] = expectation(description: "Client should call guild role create method")
        expectations[.guildRoleDelete] = expectation(description: "Client should call guild role delete method")

        let roleCreate: [String: Any] = [
            "guild_id": "testGuild",
            "role": testRole
        ]

        let roleDelete: [String: Any] = [
            "guild_id": "testGuild",
            "role_id": "testRole"
        ]

        client.handleDispatch(event: .guildCreate, data: .object(testGuildJSON))
        client.handleDispatch(event: .guildRoleCreate, data: .object(roleCreate))
        client.handleDispatch(event: .guildRoleDelete, data: .object(roleDelete))

        waitForExpectations(timeout: 0.2)
    }

    var client: DiscordClient!
    var expectations = [DiscordDispatchEvent: XCTestExpectation]()

    override func setUp() {
        client = DiscordClient(token: "Testing", delegate: self)
        expectations = [DiscordDispatchEvent: XCTestExpectation]()
    }
}

extension TestDiscordClient : DiscordClientDelegate {
    func client(_ client: DiscordClient, didCreateChannel channel: DiscordChannel) {
        func testGuildChannel(_ channel: DiscordGuildChannel) {
            guard let clientGuild = client.guilds[channel.guildId] else {
                XCTFail("Guild for channel should be in guilds")

                return
            }

            XCTAssertEqual(clientGuild.channels.count, 2, "Create channel should add new guild channel")
            XCTAssertEqual(clientGuild.channels[channel.id]?.name, "A new channel", "Create channel should correctly " +
                                                                                    "create a guild channel")
        }

        func testDMChannel(_ channel: DiscordDMChannel) {
            guard let clientChannel = client.directChannels[channel.id] else {
                XCTFail("DM channel should be in direct channels")

                return
            }

            XCTAssertEqual(clientChannel.type, .direct, "Create channel should correctly type direct channels")
            XCTAssertEqual(clientChannel.id, testUser["id"] as! String, "Channel create should index channels by " +
                                                                        "recipient id")
        }

        func testGroupDMChannel(_ channel: DiscordGroupDMChannel) { XCTFail("Checks needed for GroupDM") }

        switch channel {
        case let guildChannel as DiscordGuildChannel:      testGuildChannel(guildChannel)
        case let dmChannel as DiscordDMChannel:            testDMChannel(dmChannel)
        case let groupDmChannel as DiscordGroupDMChannel:  testGroupDMChannel(groupDmChannel)
        default: XCTFail("Unknown channel type")
        }

        expectations[.channelCreate]?.fulfill()
    }

    func client(_ client: DiscordClient, didAddGuildMember member: DiscordGuildMember) {
        guard let clientGuild = client.guilds[member.guildId] else {
            XCTFail("Guild for member should be in guilds")

            return
        }

        XCTAssertEqual(member.nick, "test nick", "Guild member add should correctly create a member")
        XCTAssertNotNil(clientGuild.members[member.user.id], "Member should be in guild after being added")
        XCTAssertEqual(clientGuild.members.count, 21, "Guild member add should correctly add a new member to members")
        XCTAssertEqual(clientGuild.memberCount, 21, "Guild member add should correctly increment the number of members")

        expectations[.guildMemberAdd]?.fulfill()
    }

    func client(_ client: DiscordClient, didRemoveGuildMember member: DiscordGuildMember) {
        guard let clientGuild = client.guilds[member.guildId] else {
            XCTFail("Guild for member should be in guilds")

            return
        }

        XCTAssertNil(clientGuild.members[member.user.id], "Guild member remove should remove member")
        XCTAssertEqual(clientGuild.members.count, 19, "Guild member remove should correctly remove a member")
        XCTAssertEqual(clientGuild.memberCount, 19, "Guild member remove should correctly decrement the number of members")

        expectations[.guildMemberRemove]?.fulfill()
    }

    func client(_ client: DiscordClient, didUpdateGuildMember member: DiscordGuildMember) {
        guard let guildMember = client.guilds[member.guildId]?.members[member.user.id] else {
            XCTFail("Guild member should be in guild")

            return
        }

        XCTAssertEqual(guildMember.nick, "a new nick", "Member on guild should be updated")

        expectations[.guildMemberUpdate]?.fulfill()
    }

    func client(_ client: DiscordClient, didCreateGuild guild: DiscordGuild) {
        guard let clientGuild = client.guilds[guild.id] else {
            XCTFail("Guild should be in guilds")

            return
        }

        XCTAssertEqual(clientGuild.channels.count, 1, "Created guild should have one channel")
        XCTAssertEqual(clientGuild.members.count, 20, "Created guild should have 20 members")
        XCTAssertEqual(clientGuild.presences.count, 20, "Created guild should have 20 presences")
        XCTAssert(guild === clientGuild, "Guild on the client should be the same as one passed to handler")

        expectations[.guildCreate]?.fulfill()
    }

    func client(_ client: DiscordClient, didDeleteGuild guild: DiscordGuild) {
        XCTAssertEqual(client.guilds.count, 0, "Client should have no guilds")
        XCTAssertEqual(guild.id, "testGuild", "Test guild should be removed")

        expectations[.guildDelete]?.fulfill()
    }

    func client(_ client: DiscordClient, didUpdateGuild guild: DiscordGuild) {
        guard let clientGuild = client.guilds[guild.id] else {
            XCTFail("Guild should be in guilds")

            return
        }

        XCTAssertEqual(clientGuild.name, "A new name", "Guild should correctly update name")
        XCTAssert(guild === clientGuild, "Guild on the client should be the same as one passed to handler")

        expectations[.guildUpdate]?.fulfill()
    }

    func client(_ client: DiscordClient, didUpdateEmojis emojis: [String: DiscordEmoji],
                onGuild guild: DiscordGuild) {
        XCTAssertEqual(guild.emojis.count, 20, "Update should have 20 emoji")

        expectations[.guildEmojisUpdate]?.fulfill()
    }

    func client(_ client: DiscordClient, didCreateRole role: DiscordRole, onGuild guild: DiscordGuild) {
        guard let clientGuild = client.guilds[guild.id] else {
            XCTFail("Guild should be in guilds")

            return
        }

        XCTAssertNotNil(clientGuild.roles[role.id], "Role should be in guild")
        XCTAssertEqual(role.name, "My Test Role", "Role create should correctly make role")

        expectations[.guildRoleCreate]?.fulfill()
    }

    func client(_ client: DiscordClient, didDeleteRole role: DiscordRole, fromGuild guild: DiscordGuild) {
        guard let clientGuild = client.guilds[guild.id] else {
            XCTFail("Guild should be in guilds")

            return
        }

        XCTAssertNil(clientGuild.roles[role.id], "Role should not be in guild")
        XCTAssertEqual(role.name, "My Test Role", "Role create should correctly make role")

        expectations[.guildRoleDelete]?.fulfill()
    }

    func client(_ client: DiscordClient, didUpdateRole role: DiscordRole, onGuild guild: DiscordGuild) {
        guard let clientGuild = client.guilds[guild.id] else {
            XCTFail("Guild should be in guilds")

            return
        }

        XCTAssertNotNil(clientGuild.roles[role.id], "Role should be in guild")
        XCTAssertEqual(role.name, "A dank role", "Role create should correctly update role")

        expectations[.guildRoleUpdate]?.fulfill()
    }
}