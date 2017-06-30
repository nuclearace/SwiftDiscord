//
//  Created by TellowKrinkle on 2017/06/26.
//

import XCTest
@testable import SwiftDiscord

class TestDiscordDataStructures : XCTestCase {
    func testRoleJSONification() {
        let role1 = DiscordRole(id: 324, color: 43, hoist: false, managed: true, mentionable: false, name: "Test Role", permissions: [.addReactions], position: 4)
        let role2 = DiscordRole(roleObject: role1.json)

        XCTAssertEqual(role1.id, role2.id, "Role ID should survive JSONification")
        XCTAssertEqual(role1.color, role2.color, "Color should survive JSONification")
        XCTAssertEqual(role1.hoist, role2.hoist, "Hoist should survive JSONification")
        XCTAssertEqual(role1.managed, role2.managed, "Managed should survive JSONification")
        XCTAssertEqual(role1.mentionable, role2.mentionable, "Mentionable should survive JSONification")
        XCTAssertEqual(role1.name, role2.name, "Name should survive JSONificaiton")
        XCTAssertEqual(role1.permissions, role2.permissions, "Permissions should survive JSONification")
        XCTAssertEqual(role1.position, role2.position, "Position should survive JSONification")
    }

    func testPermissionOverwriteJSONification() {
        let overwrite1 = DiscordPermissionOverwrite(id: 5234, type: .member, allow: [.changeNickname, .voice], deny: [.manageChannels])
        let overwrite2 = DiscordPermissionOverwrite(permissionOverwriteObject: overwrite1.json)

        XCTAssertEqual(overwrite1.id, overwrite2.id, "Permission Overwrite ID should survive JSONification")
        XCTAssertEqual(overwrite1.type, overwrite2.type, "Type should survive JSONification")
        XCTAssertEqual(overwrite1.allow, overwrite2.allow, "Allow should survive JSONification")
        XCTAssertEqual(overwrite1.deny, overwrite2.deny, "Deny should survive JSONification")
        let overwrite3 = DiscordPermissionOverwrite(id: 934, type: .role, allow: [], deny: [])
        let overwrite4 = DiscordPermissionOverwrite(permissionOverwriteObject: overwrite3.json)
        XCTAssertEqual(overwrite3.type, overwrite4.type, "Type should survive JSONification")
    }

    func testGameJSONification() {
        let game1 = DiscordGame(name: "Game", type: .game)
        let game2 = DiscordGame(gameObject: game1.json)!
        let game3 = DiscordGame(name: "Another Game", type: .stream, url: "http://www.twitch.tv/person")
        let game4 = DiscordGame(gameObject: game3.json)!
        XCTAssertEqual(game1.name, game2.name, "Name should survive JSONification")
        XCTAssertEqual(game1.type, game2.type, "Type should survive JSONification")
        XCTAssertEqual(game1.url, game2.url, "Nil URL should survive JSONification")
        XCTAssertEqual(game3.name, game4.name, "Name should survive JSONification")
        XCTAssertEqual(game3.type, game4.type, "Type should survive JSONification")
        XCTAssertEqual(game3.url, game4.url, "URL should survive JSONification")
    }
}
