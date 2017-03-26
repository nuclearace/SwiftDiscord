//
// Created by Erik Little on 3/26/17.
//

import Foundation
import XCTest
@testable import SwiftDiscord

class TestDiscordClient : XCTestCase {
    func testClientCreatesGuild() {
        expectations[.guildCreate] = expectation(description: "Client should call guild create method")

        client.handleDispatch(event: .guildCreate, data: .object(createTestGuildJSON()))

        waitForExpectations(timeout: 0.2)
    }

    func testClientUpdatesGuild() {
        expectations[.guildCreate] = expectation(description: "Client should call guild create method")
        expectations[.guildUpdate] = expectation(description: "Client should call guild update method")

        let updateJSON: [String: Any] = [
            "id": "testGuild",
            "name": "A new name"
        ]

        client.handleDispatch(event: .guildCreate, data: .object(createTestGuildJSON()))
        client.handleDispatch(event: .guildUpdate, data: .object(updateJSON))

        waitForExpectations(timeout: 0.2)
    }

    func testClientDeletesGuild() {
        expectations[.guildCreate] = expectation(description: "Client should call guild create method")
        expectations[.guildDelete] = expectation(description: "Client should call guild delete method")

        client.handleDispatch(event: .guildCreate, data: .object(createTestGuildJSON()))
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

        client.handleDispatch(event: .guildCreate, data: .object(createTestGuildJSON()))
        client.handleDispatch(event: .guildMemberAdd, data: .object(tMember))

        waitForExpectations(timeout: 0.2)
    }

    func testClientHandlesGuildMemberUpdate() {
        expectations[.guildCreate] = expectation(description: "Client should call guild create method")
        expectations[.guildMemberUpdate] = expectation(description: "Client should call guild member update method")

        var tMember = testMember
        var tUser = testUser

        tUser["id"] = "15"
        tMember["guild_id"] = "testGuild"
        tMember["user"] = tUser
        tMember["nick"] = "a new nick"

        client.handleDispatch(event: .guildCreate, data: .object(createTestGuildJSON()))
        client.handleDispatch(event: .guildMemberUpdate, data: .object(tMember))

        waitForExpectations(timeout: 0.2)
    }

    func testClientHandlesGuildMemberRemove() {
        expectations[.guildCreate] = expectation(description: "Client should call guild create method")
        expectations[.guildMemberRemove] = expectation(description: "Client should call guild member remove method")

        var tMember = testMember
        var tUser = testUser

        tUser["id"] = "15"
        tMember["guild_id"] = "testGuild"
        tMember["user"] = tUser

        client.handleDispatch(event: .guildCreate, data: .object(createTestGuildJSON()))
        client.handleDispatch(event: .guildMemberRemove, data: .object(tMember))

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
    func client(_ client: DiscordClient, didAddGuildMember member: DiscordGuildMember) {
        guard let clientGuild = client.guilds[member.guildId] else {
            XCTFail()

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
            XCTFail()

            return
        }

        XCTAssertNil(clientGuild.members[member.user.id], "Guild member remove should remove member")
        XCTAssertEqual(clientGuild.members.count, 19, "Guild member remove should correctly remove a member")
        XCTAssertEqual(clientGuild.memberCount, 19, "Guild member remove should correctly decrement the number of members")

        expectations[.guildMemberRemove]?.fulfill()
    }

    func client(_ client: DiscordClient, didUpdateGuildMember member: DiscordGuildMember) {
        guard let guildMember = client.guilds[member.guildId]?.members[member.user.id] else {
            XCTFail()

            return
        }

        XCTAssertEqual(guildMember.nick, "a new nick", "Member on guild should be updated")

        expectations[.guildMemberUpdate]?.fulfill()
    }

    func client(_ client: DiscordClient, didCreateGuild guild: DiscordGuild) {
        guard let clientGuild = client.guilds[guild.id] else {
            XCTFail()

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
            XCTFail()

            return
        }

        XCTAssertEqual(clientGuild.name, "A new name", "Guild should correctly update name")
        XCTAssert(guild === clientGuild, "Guild on the client should be the same as one passed to handler")

        expectations[.guildUpdate]?.fulfill()
    }
}
