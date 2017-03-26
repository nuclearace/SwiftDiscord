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

    var client: DiscordClient!
    var expectations = [DiscordDispatchEvent: XCTestExpectation]()

    override func setUp() {
        client = DiscordClient(token: "Testing", delegate: self)
        expectations = [DiscordDispatchEvent: XCTestExpectation]()
    }
}

extension TestDiscordClient : DiscordClientDelegate {
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
