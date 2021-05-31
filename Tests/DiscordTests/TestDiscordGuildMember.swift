//
// Created by Erik Little on 3/25/17.
//

import Foundation
import XCTest
@testable import Discord

public class TestDiscordGuildMember : XCTestCase {
    func testCreatingGuildMember() {
        var tMember = testMember
        tMember["mute"] = true
        tMember["deaf"] = true
        tMember["nick"] = "Some Test Nick"

        let member = DiscordGuildMember(guildMemberObject: tMember, guildId: guild.id, guild: guild)

        XCTAssertEqual(member.roleIds.count, 1, "Member should have 1 role id")
        XCTAssertTrue(member.deaf, "Member should deaf")
        XCTAssertTrue(member.mute, "Member should be muted")
        XCTAssertEqual(member.nick, "Some Test Nick", "Member should have a nick")
    }

    func testGettingRolesFromGuild() {
        let member = DiscordGuildMember(guildMemberObject: testMember, guildId: guild.id, guild: guild)

        XCTAssertEqual(member.roleIds.count, 1, "Member should have 1 role id")
        XCTAssertEqual(member.roles!.count, 1, "Member should have roles")
        XCTAssertEqual(member.roles![0].name, "My Test Role", "Member should have a specific role")
    }

    func testUpdatingMember() {
        var member = DiscordGuildMember(guildMemberObject: testMember, guildId: guild.id, guild: guild)

        _ = member.updateMember(["nick": "A new nick",
                                 "roles": ["400", "401"]
                                ])

        XCTAssertEqual(member.nick, "A new nick", "Member should have a new nick")
        XCTAssertEqual(member.roleIds.count, 2, "Should have new roles")
    }

    func testHasRole() {
        let member = DiscordGuildMember(guildMemberObject: testMember, guildId: guild.id, guild: guild)
        let role = DiscordRole(roleObject: testRole)

        XCTAssertTrue(member.hasRole(role.name), "Member should have the test role")
        XCTAssertFalse(member.hasRole("Some role"), "Member should not have random role")
    }

    var guild: DiscordGuild!

    public static var allTests: [(String, (TestDiscordGuildMember) -> () -> ())] {
        return [
            ("testCreatingGuildMember", testCreatingGuildMember),
            ("testGettingRolesFromGuild", testGettingRolesFromGuild),
            ("testUpdatingMember", testUpdatingMember),
            ("testHasRole", testHasRole)
        ]
    }

    public override func setUp() {
        guild = DiscordGuild(guildObject: [
            "id": "guildid",
            "roles": [testRole]
        ], client: nil)
    }
}
