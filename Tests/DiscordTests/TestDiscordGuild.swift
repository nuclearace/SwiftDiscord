//
// Created by Erik Little on 3/25/17.
//

import Foundation
import XCTest
@testable import Discord

public class TestDiscordGuild : XCTestCase {
    func testCreatingGuildSetsId() {
        let guild = DiscordGuild(guildObject: testGuild, client: nil)

        XCTAssertEqual(guild.id, 100, "init should set id")
    }

    func testCreatingGuildSetsName() {
        let guild = DiscordGuild(guildObject: testGuild, client: nil)

        XCTAssertEqual(guild.name, "Test Guild", "init should set name")
    }

    func testCreatingGuildSetsDefaultMessageNotifications() {
        let guild = DiscordGuild(guildObject: testGuild, client: nil)

        XCTAssertEqual(guild.defaultMessageNotifications, 0, "init should set default message notifications")
    }

    func testCreatingGuildSetsWidgetEnabled() {
        tGuild["widget_enabled"] = true

        let guild = DiscordGuild(guildObject: tGuild, client: nil)

        XCTAssertTrue(guild.widgetEnabled, "init should set widget enabled")
    }

    func testCreatingGuildSetsWidgetChannel() {
        tGuild["widget_channel_id"] = "200"

        let guild = DiscordGuild(guildObject: tGuild, client: nil)

        XCTAssertEqual(guild.widgetChannelId, 200, "init should set the widget channel id")
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
        tGuild["owner_id"] = "601"

        let guild = DiscordGuild(guildObject: tGuild, client: nil)

        XCTAssertEqual(guild.ownerId, 601, "init should set owner id")
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

    func testGuildCorrectlyGetsRolesForMember() {
        var tMember = testMember
        var role2 = testRole

        role2["id"] = "401"
        role2["name"] = "A new role"
        tMember["roles"] = [testRole["id"] as! String, role2["id"] as! String]

        let guild = DiscordGuild(guildObject: ["id": "guildid",
                                               "roles": [testRole, role2]
                                              ], client: nil)
        let member = DiscordGuildMember(guildMemberObject: tMember, guildId: guild.id, guild: guild)

        XCTAssertEqual(guild.roles.count, 2, "guild should have two roles")

        let roles = guild.roles(for: member)

        XCTAssertEqual(roles.count, 2, "guild should find two roles for member")
        XCTAssertNotNil(roles.first(where: { $0.id == Snowflake(testRole["id"] as! String)! }), "roles should find testrole")
        XCTAssertNotNil(roles.first(where: { $0.id == Snowflake(role2["id"] as! String)! }), "roles should find role2")
    }

    func testGuildFromObjectCorrectlyCreatesChannelCategory() {
        switch guildChannel(fromObject: testGuildChannelCategory, guildID: nil) {
        case let channel as DiscordGuildChannelCategory:
            XCTAssertEqual(Snowflake(testGuildChannelCategory["id"] as! String), channel.id,
                           "It should create a guild category id correctly")
        default:
            XCTFail("It should create a guild category")
        }
    }

    func testGuildFromObjectCorrectlyCreatesTextChannel() {
        switch guildChannel(fromObject: testGuildTextChannel, guildID: nil) {
        case let channel as DiscordGuildTextChannel:
            XCTAssertEqual(Snowflake(testGuildTextChannel["id"] as! String), channel.id,
                           "It should create a guild text channel id correctly")
        default:
            XCTFail("It should create a guild text channel")
        }
    }

    func testGuildFromObjectCorrectlyCreatesVoiceChannel() {
        switch guildChannel(fromObject: testGuildVoiceChannel, guildID: nil) {
        case let channel as DiscordGuildVoiceChannel:
            XCTAssertEqual(Snowflake(testGuildVoiceChannel["id"] as! String), channel.id,
                           "It should create a guild voice channel id correctly")
            XCTAssertEqual(testGuildVoiceChannel["bitrate"] as! Int, channel.bitrate,
                           "It should create a guild voice channel bitrate correctly")
        default:
            XCTFail("It should create a guild category")
        }
    }

    func testGuildFromObjectCreatesNoChannelOnInvalidType() {
        var newChannel = testGuildTextChannel

        newChannel["type"] = 200

        switch guildChannel(fromObject: newChannel, guildID: nil) {
        case .some:
            XCTFail("It should not crete a channel if the type is not known")
        default:
            break
        }
    }

    func testGuildReturnsABasicMemberObjectLazyCreationFails() {
        let guild = DiscordGuild(guildObject: tGuild, client: nil)
        var tPresence = testPresence

        tPresence["status"] = "online"

        let presence = DiscordPresence(presenceObject: testPresence, guildId: guild.id)

        guild.updateGuild(fromPresence: presence, fillingUsers: true, pruningUsers: false)

        XCTAssertEqual(guild.members.count, 1, "It should add a placeholder member")
        XCTAssertEqual(guild.members[presence.user.id]?.user.id, presence.user.id, "It should create a basic member")
    }

#if PERFTEST
    func testCreatingGuildWithALargeNumberOfMembersIsConsistent() {
        tGuild["members"] = createGuildMemberObjects(n: 100_000)

        var guild: DiscordGuild!

        measure {
            guild = DiscordGuild(guildObject: self.tGuild, client: nil)
        }

        XCTAssertEqual(guild.members.count, 100_000, "init should create 100_000 members")
        XCTAssertEqual(guild.members[5000]?.user.id, 5000, "init should create members correctly")
    }

    func testCreatingGuildWithALargeNumberOfPresencesIsConsistent() {
        tGuild["presences"] = createPresenceObjects(n: 100_000)

        var guild: DiscordGuild!

        measure {
            guild = DiscordGuild(guildObject: self.tGuild, client: nil)
        }

        XCTAssertEqual(guild.presences.count, 100_000, "init should create 100_000 presences")
        XCTAssertEqual(guild.presences[5000]?.user.id, 5000, "init should create presences correctly")
    }
    #endif

    var tGuild: [String: Any]!

    public static var allTests: [(String, (TestDiscordGuild) -> () -> ())] {
        var tests = [
            ("testCreatingGuildSetsId", testCreatingGuildSetsId),
            ("testCreatingGuildSetsName", testCreatingGuildSetsName),
            ("testCreatingGuildSetsDefaultMessageNotifications", testCreatingGuildSetsDefaultMessageNotifications),
            ("testCreatingGuildSetsWidgetEnabled", testCreatingGuildSetsWidgetEnabled),
            ("testCreatingGuildSetsWidgetChannel", testCreatingGuildSetsWidgetChannel),
            ("testCreatingGuildSetsIcon", testCreatingGuildSetsIcon),
            ("testCreatingGuildSetsLarge", testCreatingGuildSetsLarge),
            ("testCreatingGuildSetsMemberCount", testCreatingGuildSetsMemberCount),
            ("testCreatingGuildSetsMFALevel", testCreatingGuildSetsMFALevel),
            ("testCreatingGuildSetsOwnerId", testCreatingGuildSetsOwnerId),
            ("testCreatingGuildSetsRegion", testCreatingGuildSetsRegion),
            ("testCreatingGuildSetsSplash", testCreatingGuildSetsSplash),
            ("testCreatingGuildSetsVerificationLevel", testCreatingGuildSetsVerificationLevel),
            ("testCreatingGuildSetsUnavailable", testCreatingGuildSetsUnavailable),
            ("testGuildCorrectlyGetsRolesForMember", testGuildCorrectlyGetsRolesForMember),
            ("testGuildFromObjectCorrectlyCreatesChannelCategory", testGuildFromObjectCorrectlyCreatesChannelCategory),
            ("testGuildFromObjectCorrectlyCreatesTextChannel", testGuildFromObjectCorrectlyCreatesTextChannel),
            ("testGuildFromObjectCorrectlyCreatesVoiceChannel", testGuildFromObjectCorrectlyCreatesVoiceChannel),
            ("testGuildFromObjectCreatesNoChannelOnInvalidType", testGuildFromObjectCreatesNoChannelOnInvalidType),
            ("testGuildReturnsABasicMemberObjectLazyCreationFails", testGuildReturnsABasicMemberObjectLazyCreationFails)
        ]

        #if PERFTEST
        tests += [
            ("testCreatingGuildWithALargeNumberOfMembersIsConsistent", testCreatingGuildWithALargeNumberOfMembersIsConsistent),
            ("testCreatingGuildWithALargeNumberOfPresencesIsConsistent", testCreatingGuildWithALargeNumberOfPresencesIsConsistent),
        ]
        #endif

        return tests
    }

    public override func setUp() {
        tGuild = testGuild
    }
}
