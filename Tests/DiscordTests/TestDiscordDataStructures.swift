//
//  Created by TellowKrinkle on 2017/06/26.
//

import XCTest
@testable import Discord

extension DiscordGatewayPayloadData: Equatable {
    public static func ==(lhs: DiscordGatewayPayloadData, rhs: DiscordGatewayPayloadData) -> Bool {
        switch (lhs, rhs) {
        case let (.bool(lhsbool), .bool(rhsbool)):
            return lhsbool == rhsbool
        case let (.integer(lhsint), .integer(rhsint)):
            return lhsint == rhsint
        default:
            return false
        }
    }
}

func roundTripEncode<T: Encodable>(_ item: T) -> [String: Any] {
    let json = JSON.encodeJSONData(item)!
    return try! JSONSerialization.jsonObject(with: json, options: []) as! [String: Any]
}

public class TestDiscordDataStructures : XCTestCase {

    func testRoleJSONification() {
        let role1 = DiscordRole(id: 324, color: 43, hoist: false, managed: true, mentionable: false, name: "Test Role", permissions: [.addReactions], position: 4)
        let role2 = DiscordRole(roleObject: roundTripEncode(role1))

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
        let overwrite2 = DiscordPermissionOverwrite(permissionOverwriteObject: roundTripEncode(overwrite1))

        XCTAssertEqual(overwrite1.id, overwrite2.id, "Permission Overwrite ID should survive JSONification")
        XCTAssertEqual(overwrite1.type, overwrite2.type, "Type should survive JSONification")
        XCTAssertEqual(overwrite1.allow, overwrite2.allow, "Allow should survive JSONification")
        XCTAssertEqual(overwrite1.deny, overwrite2.deny, "Deny should survive JSONification")
        let overwrite3 = DiscordPermissionOverwrite(id: 934, type: .role, allow: [], deny: [])
        let overwrite4 = DiscordPermissionOverwrite(permissionOverwriteObject: roundTripEncode(overwrite3))
        XCTAssertEqual(overwrite3.type, overwrite4.type, "Type should survive JSONification")
    }

    func testGameJSONification() {
        let game1 = DiscordActivity(name: "Game", type: .game)
        let game2 = DiscordActivity(gameObject: roundTripEncode(game1))!
        let game3 = DiscordActivity(name: "Another Game", type: .stream, url: "http://www.twitch.tv/person")
        let game4 = DiscordActivity(gameObject: roundTripEncode(game3))!
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
        let embed2 = DiscordEmbed(embedObject: roundTripEncode(embed1))
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
        let embed4 = DiscordEmbed(embedObject: roundTripEncode(embed3))
        currentCompare = "embed3 and embed4"
        compare(embed3, embed4)
        let nilJSONTest = JSON.encodeJSON(embed3)!
        XCTAssertFalse(nilJSONTest.contains("null"), "JSON-encoded embed should not have any null fields")
    }

    func testDiscordGatewayPayloadData() {
        let dic = try! JSONSerialization.jsonObject(with: "[true, false, 0, 1, 2, -1]".data(using: .utf8)!, options: []) as! [Any]
        let payloadData = dic.map(DiscordGatewayPayloadData.dataFromDictionary)
        XCTAssertEqual(payloadData[0], DiscordGatewayPayloadData.bool(true), "Discord Gateway Payload should unwrap true")
        XCTAssertEqual(payloadData[1], DiscordGatewayPayloadData.bool(false), "Discord Gateway Payload should unwrap false")
        XCTAssertEqual(payloadData[2], DiscordGatewayPayloadData.integer(0), "Discord Gateway Payload should unwrap 0")
        XCTAssertEqual(payloadData[3], DiscordGatewayPayloadData.integer(1), "Discord Gateway Payload should unwrap 1")
        XCTAssertEqual(payloadData[4], DiscordGatewayPayloadData.integer(2), "Discord Gateway Payload should unwrap 2")
        XCTAssertEqual(payloadData[5], DiscordGatewayPayloadData.integer(-1), "Discord Gateway Payload should unwrap -1")
    }

    func testDiscordGatewayPayload() {
        func testRunner(data: DiscordGatewayPayloadData, test: (Any?) -> ()) {
            let payload = DiscordGatewayPayload(code: .gateway(.identify), payload: data, sequenceNumber: 9, name: "hi")
            let json = payload.createPayloadString()!
            let object = try! JSONSerialization.jsonObject(with: json.data(using: .utf8)!, options: []) as! [String: Any]
            XCTAssertEqual(object["op"] as? Int, payload.code.rawCode)
            XCTAssertEqual(object["s"] as? Int, payload.sequenceNumber)
            XCTAssertEqual(object["t"] as? String, payload.name)
            test(object["d"])
        }
        testRunner(data: .bool(true)) { item in
            XCTAssertEqual(item as? Bool, true)
        }
        testRunner(data: .bool(false)) { item in
            XCTAssertEqual(item as? Bool, false)
        }
        testRunner(data: .integer(8)) { item in
            XCTAssertEqual(item as? Int, 8)
        }
        testRunner(data: .object(["hello": 4, "yay": DiscordActivity(name: "A Game", type: .stream)])) { item in
            let item = item as! [String: Any]
            XCTAssertEqual(item["hello"] as? Int, 4)
            XCTAssertNotNil(item["yay"])
            let game = DiscordActivity(gameObject: item["yay"] as? [String: Any])
            XCTAssertEqual(game?.name, "A Game")
            XCTAssertEqual(game?.type, .stream)
        }
        let perms = DiscordPermissionOverwrite(id: 95352, type: .member, allow: [.addReactions, .attachFiles], deny: [.changeNickname, .manageChannels])
        testRunner(data: .customEncodable(perms)) { (item) in
            let newPerms = DiscordPermissionOverwrite(permissionOverwriteObject: item as? [String: Any] ?? [:])
            XCTAssertEqual(newPerms.id, perms.id)
            XCTAssertEqual(newPerms.type, perms.type)
            XCTAssertEqual(newPerms.allow, perms.allow)
            XCTAssertEqual(newPerms.deny, perms.deny)
        }
    }

    public static var allTests: [(String, (TestDiscordDataStructures) -> () -> ())] {
        return [
            ("testRoleJSONification", testRoleJSONification),
            ("testPermissionOverwriteJSONification", testPermissionOverwriteJSONification),
            ("testGameJSONification", testGameJSONification),
            ("testEmbedJSONification", testEmbedJSONification),
            ("testDiscordGatewayPayloadData", testDiscordGatewayPayloadData),
            ("testDiscordGatewayPayload", testDiscordGatewayPayload),
        ]
    }

}
