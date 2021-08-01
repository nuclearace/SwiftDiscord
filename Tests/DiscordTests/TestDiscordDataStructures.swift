//
//  Created by TellowKrinkle on 2017/06/26.
//

import XCTest
@testable import Discord

func roundTripEncode<T: Codable>(_ item: T) -> T {
    let data = try! DiscordJSON.encode(item)
    return try! DiscordJSON.decode(data)
}

public class TestDiscordDataStructures : XCTestCase {

    func testRoleJSONification() {
        let role1 = DiscordRole(id: 324, color: 43, hoist: false, managed: true, mentionable: false, name: "Test Role", permissions: [.addReactions], position: 4)
        let role2 = roundTripEncode(role1)

        XCTAssertEqual(role1.id, role2.id, "Role ID should survive JSONification")
        XCTAssertEqual(role1.color, role2.color, "Color should survive JSONification")
        XCTAssertEqual(role1.hoist, role2.hoist, "Hoist should survive JSONification")
        XCTAssertEqual(role1.managed, role2.managed, "Managed should survive JSONification")
        XCTAssertEqual(role1.mentionable, role2.mentionable, "Mentionable should survive JSONification")
        XCTAssertEqual(role1.name, role2.name, "Name should survive JSONification")
        XCTAssertEqual(role1.permissions, role2.permissions, "Permissions should survive JSONification")
        XCTAssertEqual(role1.position, role2.position, "Position should survive JSONification")
    }

    func testPermissionOverwriteJSONification() {
        let overwrite1 = DiscordPermissionOverwrite(id: 5234, type: .member, allow: [.changeNickname, .voice], deny: [.manageChannels])
        let overwrite2 = roundTripEncode(overwrite1)

        XCTAssertEqual(overwrite1.id, overwrite2.id, "Permission Overwrite ID should survive JSONification")
        XCTAssertEqual(overwrite1.type, overwrite2.type, "Type should survive JSONification")
        XCTAssertEqual(overwrite1.allow, overwrite2.allow, "Allow should survive JSONification")
        XCTAssertEqual(overwrite1.deny, overwrite2.deny, "Deny should survive JSONification")
        let overwrite3 = DiscordPermissionOverwrite(id: 934, type: .role, allow: [], deny: [])
        let overwrite4 = roundTripEncode(overwrite3)
        XCTAssertEqual(overwrite3.type, overwrite4.type, "Type should survive JSONification")
    }

    func testGameJSONification() {
        let game1 = DiscordActivity(name: "Game", type: .game)
        let game2 = roundTripEncode(game1)
        let game3 = DiscordActivity(name: "Another Game", type: .stream, url: "http://www.twitch.tv/person")
        let game4 = roundTripEncode(game3)
        XCTAssertEqual(game1.name, game2.name, "Name should survive JSONification")
        XCTAssertEqual(game1.type, game2.type, "Type should survive JSONification")
        XCTAssertEqual(game1.url, game2.url, "Nil URL should survive JSONification")
        XCTAssertEqual(game3.name, game4.name, "Name should survive JSONification")
        XCTAssertEqual(game3.type, game4.type, "Type should survive JSONification")
        XCTAssertEqual(game3.url, game4.url, "URL should survive JSONification")
    }

    func testEmbedJSONification() {
        let dummyIconA = URL(string: "https://cdn.discordapp.com/embed/avatars/0.png")!
        let dummyIconB = URL(string: "https://cdn.discordapp.com/embed/avatars/1.png")!
        let dummyURL = URL(string: "https://discord.com")!

        let embed1 = DiscordEmbed(
            title: "Title",
            description: "Description",
            author: DiscordEmbed.Author(name: "Author", iconURL: dummyIconA, url: dummyURL, proxyIconURL: dummyIconB),
            url: dummyURL,
            image: DiscordEmbed.Image(url: dummyIconA, width: 3245, height: 1493),
            timestamp: Date(timeIntervalSince1970: 429384.25), // Must be losslessly convertible to RFC3339
            thumbnail: DiscordEmbed.Thumbnail(url: dummyIconB, width: 2934, height: 9534, proxyURL: dummyIconA),
            color: 423,
            footer: DiscordEmbed.Footer(text: "Footer", iconUrl: dummyIconB),
            fields: [DiscordEmbed.Field(name: "Field Name", value: "Field Value", inline: true)]
        )
        let embed2 = roundTripEncode(embed1)
        var currentCompare = "embed1 and embed2"
        func check<T: Equatable>(_ lhs: T?, _ rhs: T?, _ name: String) {
            XCTAssertEqual(lhs, rhs, "\(name) should survive JSONification (comparing \(currentCompare))")
        }
        func compare(_ embed1: DiscordEmbed, _ embed2: DiscordEmbed) {
            check(embed1.title, embed2.title, "Title")
            check(embed1.description, embed2.description, "Description")
            check(embed1.author?.name, embed2.author?.name, "Author name")
            check(embed1.author?.iconUrl, embed2.author?.iconUrl, "Author icon URL")
            check(embed1.author?.url, embed2.author?.url, "Author URL")
            check(embed1.author?.proxyIconUrl, embed2.author?.proxyIconUrl, "Author proxy url")
            check(embed1.url, embed2.url, "URL")
            check(embed1.image?.url, embed2.image?.url, "Image URL")
            check(embed1.image?.width, embed2.image?.width, "Image width")
            check(embed1.image?.height, embed2.image?.height, "Image height")
            check(embed1.timestamp, embed2.timestamp, "Timestamp")
            check(embed1.thumbnail?.url, embed2.thumbnail?.url, "Thumbnail URL")
            check(embed1.thumbnail?.width, embed2.thumbnail?.width, "Thumbnail width")
            check(embed1.thumbnail?.height, embed2.thumbnail?.height, "Thumbnail height")
            check(embed1.thumbnail?.proxyUrl, embed2.thumbnail?.proxyUrl, "Thumbnail proxy URL")
            check(embed1.color, embed2.color, "Color")
            check(embed1.footer?.text, embed2.footer?.text, "Footer text")
            check(embed1.footer?.iconUrl, embed2.footer?.iconUrl, "Footer icon URL")
            check(embed1.footer?.proxyIconUrl, embed2.footer?.proxyIconUrl, "Footer proxy URL")
            check(embed1.fields.count, embed2.fields.count, "Field count")
            check(embed1.fields.first?.name, embed2.fields.first?.name, "Field name")
            check(embed1.fields.first?.value, embed2.fields.first?.value, "Field value")
            check(embed1.fields.first?.inline, embed2.fields.first?.inline, "Field inline")
        }
        compare(embed1, embed2)
        let embed3 = DiscordEmbed(author: DiscordEmbed.Author(name: "Author"), image: DiscordEmbed.Image(url: dummyIconA), thumbnail: DiscordEmbed.Thumbnail(url: dummyIconA), footer: DiscordEmbed.Footer(text: "Footer", iconUrl: nil))
        let embed4 = roundTripEncode(embed3)
        currentCompare = "embed3 and embed4"
        compare(embed3, embed4)
        let nilJSONTest = String(data: try! DiscordJSON.encode(embed3), encoding: .utf8)!
        XCTAssertFalse(nilJSONTest.contains("null"), "JSON-encoded embed should not have any null fields")
    }

    public static var allTests: [(String, (TestDiscordDataStructures) -> () -> ())] {
        return [
            ("testRoleJSONification", testRoleJSONification),
            ("testPermissionOverwriteJSONification", testPermissionOverwriteJSONification),
            ("testGameJSONification", testGameJSONification),
            ("testEmbedJSONification", testEmbedJSONification),
        ]
    }

}
