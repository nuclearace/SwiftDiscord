//
// Created by Erik Little on 3/25/17.
//

import Foundation
import XCTest
@testable import SwiftDiscord

class TestDiscordGuild : XCTestCase {
    var tGuild: [String: Any]!

    func testCreatingGuildSetsId() {
        let guild = DiscordGuild(guildObject: testGuild, client: nil)

        XCTAssertEqual(guild.id, "testGuild", "init should set id")
    }

    func testCreatingGuildSetsName() {
        let guild = DiscordGuild(guildObject: testGuild, client: nil)

        XCTAssertEqual(guild.name, "Test Guild", "init should set name")
    }

    func testCreatingGuildSetsDefaultMessageNotifications() {
        let guild = DiscordGuild(guildObject: testGuild, client: nil)

        XCTAssertEqual(guild.defaultMessageNotifications, 0, "init should set default message notifications")
    }

    func testCreatingGuildSetsEmbedEnabled() {
        tGuild["embed_enabled"] = true

        let guild = DiscordGuild(guildObject: tGuild, client: nil)

        XCTAssertTrue(guild.embedEnabled, "init should set embed enabled")
    }

    func testCreatingGuildSetsEmbedChannel() {
        tGuild["embed_channel_id"] = "testChannel"

        let guild = DiscordGuild(guildObject: tGuild, client: nil)

        XCTAssertEqual(guild.embedChannelId, "testChannel", "init should set the embed channel id")
    }

    func testCreatingGuildSetsIcon() {
        tGuild["icon"] = "someicon"

        let guild = DiscordGuild(guildObject: tGuild, client: nil)

        XCTAssertEqual(guild.icon, "someicon", "init should set icon")
    }

    func testCreatingGuildSetsLarge() {
        tGuild["large"] = true

        let guild = DiscordGuild(guildObject: tGuild, client: nil)

        XCTAssertTrue(guild.large, "init should set large")
    }

    func testCreatingGuildSetsMemberCount() {
        tGuild["member_count"] = 20000

        let guild = DiscordGuild(guildObject: tGuild, client: nil)

        XCTAssertEqual(guild.memberCount, 20000, "init should set member count")
    }

    func testCreatingGuildSetsMFALevel() {
        tGuild["mfa_level"] = 1

        let guild = DiscordGuild(guildObject: tGuild, client: nil)

        XCTAssertEqual(guild.mfaLevel, 1, "init should set MFA level")
    }

    func testCreatingGuildSetsOwnerId() {
        tGuild["owner_id"] = "someowner"

        let guild = DiscordGuild(guildObject: tGuild, client: nil)

        XCTAssertEqual(guild.ownerId, "someowner", "init should set owner id")
    }

    func testCreatingGuildSetsRegion() {
        tGuild["region"] = "us-east"

        let guild = DiscordGuild(guildObject: tGuild, client: nil)

        XCTAssertEqual(guild.region, "us-east", "init should set region")
    }

    func testCreatingGuildSetsSplash() {
        tGuild["splash"] = "somesplash"

        let guild = DiscordGuild(guildObject: tGuild, client: nil)

        XCTAssertEqual(guild.splash, "somesplash", "init should set splash")
    }

    func testCreatingGuildSetsVerificationLevel() {
        tGuild["verification_level"] = 1

        let guild = DiscordGuild(guildObject: tGuild, client: nil)

        XCTAssertEqual(guild.verificationLevel, 1, "init should set verification level")
    }

    func testCreatingGuildSetsUnavailable() {
        tGuild["unavailable"] = true

        let guild = DiscordGuild(guildObject: tGuild, client: nil)

        XCTAssertTrue(guild.unavailable, "init should set unavailable")
    }

    override func setUp() {
        tGuild = testGuild
    }
}
