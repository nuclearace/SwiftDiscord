//
// Created by Erik Little on 9/27/17.
//

import Foundation
import XCTest
@testable import Discord

public class TestDiscordMessage : XCTestCase, DiscordClientDelegate {
    func testGettingChannel() {
        let message = DiscordMessage(messageObject: testMessage, client: client)

        guard let channel = message.channel else {
            XCTFail("It should correctly find the channel")

            return
        }

        XCTAssertEqual(channel.id, self.channel.id, "It should find the correct channel")
    }

    func testGettingGuildMember() {
        let message = DiscordMessage(messageObject: testMessage, client: client)

        guard let member = message.guildMember else {
            XCTFail("It should correctly find the member")

            return
        }

        XCTAssertEqual(member.user.id, self.member.user.id, "It should find the correct member")
    }

    public static var allTests: [(String, (TestDiscordMessage) -> () -> ())] {
        return [
            ("testGettingChannel", testGettingChannel),
            ("testGettingGuildMember", testGettingGuildMember)
        ]
    }

    var channel: DiscordTextChannel!
    var client: DiscordClient!
    var member: DiscordGuildMember!

    public override func setUp() {
        client = DiscordClient(token: "", delegate: self)

        var member = testMember

        member["guild_id"] = testGuild["id"] as! String

        client.handleDispatch(event: .guildCreate, data: .object(testGuild))
        client.handleDispatch(event: .channelCreate, data: .object(testGuildTextChannel))
        client.handleDispatch(event: .guildMemberAdd, data: .object(member))

        super.setUp()
    }
}

public extension TestDiscordMessage {
    func client(_ client: DiscordClient, didAddGuildMember member: DiscordGuildMember) {
        self.member = member
    }

    func client(_ client: DiscordClient, didCreateChannel channel: DiscordChannel) {
        self.channel = channel as! DiscordTextChannel
    }
}
