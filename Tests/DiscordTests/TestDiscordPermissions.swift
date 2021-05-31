//
//  Created by TellowKrinkle on 2017/06/22.
//

import Foundation
import XCTest
@testable import Discord

public class TestDiscordPermissions : XCTestCase {
    func testBasicPermissions() {
        let channel = createPermissionTestChannel(overwrites: [])

        XCTAssertEqual(channel.permissionOverwrites.count, 0, "There should be no permission overwrites for this test!")

        XCTAssertTrue(channel.canMember(permissionsTestMembers[0], .banMembers), "Owners should be able to do anything")
        XCTAssertTrue(channel.canMember(permissionsTestMembers[1], .manageWebhooks), "Admins should be able to do anything")
        XCTAssertTrue(channel.canMember(permissionsTestMembers[2], .manageRoles), "Users should be able to do things allowed by their roles")
        XCTAssertFalse(channel.canMember(permissionsTestMembers[4], .manageRoles), "Users should not be able to do things not allowed by their roles")
    }

    func testRoleOverrides() {
        let channel = createPermissionTestChannel(overwrites: roleOverwrites)

        XCTAssertEqual(channel.permissionOverwrites.count, roleOverwrites.count, "There should be the same number of permission overwrites in this channel as we put in")

        XCTAssertFalse(channel.canMember(permissionsTestMembers[2], .readMessageHistory), "@everyone role should be applied to all members")
        XCTAssertTrue(channel.canMember(permissionsTestMembers[2], .viewAuditLog), "@everyone role should be applied to all members")
        XCTAssertFalse(channel.canMember(permissionsTestMembers[4], .viewAuditLog), "@everyone permission should be overridden by permissions for a specific role")
        XCTAssertTrue(channel.canMember(permissionsTestMembers[0], .sendMessages), "Owner should override all permissions")
        XCTAssertTrue(channel.canMember(permissionsTestMembers[1], .readMessages), "Admin role should override all permissions")
        XCTAssertTrue(channel.canMember(permissionsTestMembers[4], .addReactions), "An allow override should go over a deny of the same type")
        XCTAssertTrue(channel.canMember(permissionsTestMembers[3], .addReactions), "An allow override should go over a deny of the same type even if the deny is higher on the list")
        XCTAssertFalse(channel.canMember(permissionsTestMembers[4], .sendMessages), "A role permission deny should be properly applied to a normal user")
        XCTAssertFalse(channel.canMember(permissionsTestMembers[2], .addReactions), "A role permission deny should be properly applied to a normal user")
    }

    func testUserOverrides() {
        let channel = createPermissionTestChannel(overwrites: userOverwrites + roleOverwrites)

        XCTAssertEqual(channel.permissionOverwrites.count, roleOverwrites.count + userOverwrites.count, "There should be the same number of permission overwrites in this channel as we put in")

        XCTAssertTrue(channel.canMember(permissionsTestMembers[0], .manageMessages), "Owner should override all permissions")
        XCTAssertTrue(channel.canMember(permissionsTestMembers[1], .manageWebhooks), "Admin role should override all permissions")
        XCTAssertTrue(channel.canMember(permissionsTestMembers[2], .addReactions), "User permissions should override role permissions")
        XCTAssertFalse(channel.canMember(permissionsTestMembers[2], .manageMessages), "A user permission deny should be properly applied to a normal user")
        XCTAssertFalse(channel.canMember(permissionsTestMembers[3], .addReactions), "User permissions should override role permissions that overrode other role permissions")
        XCTAssertTrue(channel.canMember(permissionsTestMembers[4], .embedLinks), "User permissions should be properly applied to a normal user")
        XCTAssertTrue(channel.canMember(permissionsTestMembers[4], .sendMessages), "A user allow should override a role deny")
    }

    func testOverwritesWithDependencies() {
        let channel = createPermissionTestChannel(overwrites: depencencyOverwrites)

        XCTAssertEqual(channel.permissionOverwrites.count, depencencyOverwrites.count, "There should be the same number of permission overwrites in this channel as we put in")

        XCTAssertFalse(channel.canMember(permissionsTestMembers[4], .sendMessages), "A user who can't read messages shouldn't be able to send them")
        XCTAssertEqual(channel.permissions(for: permissionsTestMembers[4]).intersection([.createInstantInvite, .manageChannels, .addReactions, .sendMessages, .sendTTSMessages, .manageMessages, .embedLinks, .attachFiles, .readMessageHistory, .mentionEveryone, .useExternalEmojis]), [], "A user who can't read messages shouldn't be able to do any channel-related things")
        XCTAssertFalse(channel.canMember(permissionsTestMembers[4], .sendTTSMessages), "A user who can't send messages shouldn't be able to send TTS messages")
        XCTAssertTrue(channel.canMember(permissionsTestMembers[3], .sendMessages), "A user who has conflicting read messages permissions where the allow is used shouldn't have dependencies blocked")
        XCTAssertEqual(channel.permissions(for: permissionsTestMembers[2]).intersection([.sendTTSMessages, .embedLinks, .attachFiles, .mentionEveryone]), [], "A user who can't send messages shouldn't be able to send TTS messages, embed links, attach files, or mention everyone")
    }

    let roleOverwrites = [
        DiscordPermissionOverwrite(id: GuildID(testGuild.get("id", as: String.self))!, type: .role, allow: .viewAuditLog, deny: .readMessageHistory),
        DiscordPermissionOverwrite(id: permissionsTestRoles[3].id, type: .role, allow: [], deny: [.sendMessages, .addReactions, .viewAuditLog]),
        DiscordPermissionOverwrite(id: permissionsTestRoles[2].id, type: .role, allow: .addReactions, deny: []),
        DiscordPermissionOverwrite(id: permissionsTestRoles[0].id, type: .role, allow: [], deny: .readMessages),
        DiscordPermissionOverwrite(id: permissionsTestRoles[1].id, type: .role, allow: [], deny: .addReactions)
    ]

    let userOverwrites = [
        DiscordPermissionOverwrite(id: permissionsTestUsers[0].id, type: .member, allow: [], deny: .manageMessages),
        DiscordPermissionOverwrite(id: permissionsTestUsers[1].id, type: .member, allow: [], deny: .manageWebhooks),
        DiscordPermissionOverwrite(id: permissionsTestUsers[2].id, type: .member, allow: .addReactions, deny: .manageMessages),
        DiscordPermissionOverwrite(id: permissionsTestUsers[3].id, type: .member, allow: [], deny: .addReactions),
        DiscordPermissionOverwrite(id: permissionsTestUsers[4].id, type: .member, allow: [.embedLinks, .sendMessages], deny: [])
    ]

    let depencencyOverwrites = [
        DiscordPermissionOverwrite(id: permissionsTestRoles[2].id, type: .role, allow: [], deny: .readMessages),
        DiscordPermissionOverwrite(id: permissionsTestUsers[4].id, type: .member, allow: [.createInstantInvite, .manageChannels, .addReactions, .sendMessages, .sendTTSMessages, .manageMessages, .embedLinks, .attachFiles, .readMessageHistory, .mentionEveryone, .useExternalEmojis], deny: []),
        DiscordPermissionOverwrite(id: permissionsTestUsers[3].id, type: .member, allow: .readMessages, deny: []),
        DiscordPermissionOverwrite(id: permissionsTestUsers[2].id, type: .member, allow: [.sendTTSMessages, .embedLinks, .attachFiles, .mentionEveryone], deny: .sendMessages)
    ]

    public static var allTests: [(String, (TestDiscordPermissions) -> () -> ())] {
        return [
            ("testBasicPermissions", testBasicPermissions),
            ("testRoleOverrides", testRoleOverrides),
            ("testUserOverrides", testUserOverrides),
            ("testOverwritesWithDependencies", testOverwritesWithDependencies),
        ]
    }

    public override func setUp() {
        permissionsTestClient.handleGuildCreate(with: permissionsTestGuildJSON)
    }

    public override func tearDown() {
        permissionsTestClient.handleGuildDelete(with: permissionsTestGuildJSON)
        XCTAssertEqual(permissionsTestClient.channelCache.count, 0, "Removing guild should clear its channels from the channel cache")
    }
}

let permissionsTestUsers = ["23416345", "32564235", "4359835345", "32499342123", "234234120985"].map({ id -> DiscordUser in
    var tmp = testUser
    tmp["id"] = id
    return DiscordUser(userObject: tmp)
})

let permissionsTestUserPermissions: DiscordPermission = [.createInstantInvite, .addReactions, .readMessages, .sendMessages, .readMessageHistory, .useExternalEmojis, .connect, .speak, .useVAD, .changeNickname]
let permissionsTestRoles: [DiscordRole] = [
    DiscordRole(id: 2349683489545, color: 10181046, hoist: true, managed: false, mentionable: true, name: "Admin", permissions: .administrator, position: 3),
    DiscordRole(id: 32423425264343, color: 10718666, hoist: true, managed: false, mentionable: true, name: "Mod", permissions: permissionsTestUserPermissions.union([.kickMembers, .manageChannels, .viewAuditLog, .sendTTSMessages, .embedLinks, .attachFiles, .mentionEveryone, .muteMembers, .deafenMembers, .moveMembers, .manageNicknames, .manageRoles]), position: 2),
    DiscordRole(id: 34634634534564, color: 567526, hoist: true, managed: false, mentionable: true, name: "Test", permissions: permissionsTestUserPermissions, position: 1),
    DiscordRole(id: 34029736498534, color: 0, hoist: false, managed: false, mentionable: false, name: "Muted", permissions: permissionsTestUserPermissions, position: 0)
]

class PermissionsTestClientDelegate: DiscordClientDelegate { }
let permissionsTestClientDelegate = PermissionsTestClientDelegate()
let permissionsTestClient = DiscordClient(token: "Testing", delegate: permissionsTestClientDelegate)

let permissionsTestGuildJSON = { () -> [String: Any] in
    var tmp = testGuild
    tmp["owner_id"] = String(describing: permissionsTestUsers[0].id)
    tmp["roles"] = permissionsTestRoles

    return roundTripEncode(GenericEncodableDictionary(tmp))
}()

let permissionsTestGuild = DiscordGuild(guildObject: permissionsTestGuildJSON, client: permissionsTestClient)

let permissionTestMemberRoles: [[RoleID]] = [
    [permissionsTestRoles[3].id],
    [permissionsTestRoles[0].id, permissionsTestRoles[2].id],
    [permissionsTestRoles[1].id],
    [permissionsTestRoles[1].id, permissionsTestRoles[2].id],
    [permissionsTestRoles[2].id, permissionsTestRoles[3].id]
]

let permissionsTestMembers = zip(permissionsTestUsers, permissionTestMemberRoles).map({zipped -> DiscordGuildMember in
    let (user, roles) = zipped
    
    return DiscordGuildMember(guildId: permissionsTestGuild.id, user: user, deaf: false, mute: false, nick: nil, roles: roles, joinedAt: DiscordDateFormatter.format("2017-04-25T20:00:00.000000+00:00")!, guild: permissionsTestGuild)
})

func createPermissionTestChannel(overwrites: [DiscordPermissionOverwrite]) -> DiscordGuildTextChannel {
    var channelData = testGuildTextChannel
    channelData["permission_overwrites"] = overwrites
    channelData["guild_id"] = String(describing: permissionsTestGuild.id)
    channelData = roundTripEncode(GenericEncodableDictionary(channelData))
    permissionsTestClient.handleChannelCreate(with: channelData)
    return permissionsTestClient.findChannel(fromId: Snowflake(channelData["id"] as! String)!) as! DiscordGuildTextChannel
}
