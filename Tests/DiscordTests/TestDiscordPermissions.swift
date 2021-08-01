//
//  Created by TellowKrinkle on 2017/06/22.
//

import Foundation
import XCTest
@testable import Discord

public class TestDiscordPermissions: XCTestCase {
    func testBasicPermissions() {
        let channel = createPermissionTestChannel(overwrites: [])

        XCTAssertEqual(channel.permissionOverwrites?.count, 0, "There should be no permission overwrites for this test!")

        XCTAssertTrue(permissionsTestGuild.canMember(permissionsTestMembers[0], .banMembers, in: channel.id), "Owners should be able to do anything")
        XCTAssertTrue(permissionsTestGuild.canMember(permissionsTestMembers[1], .manageWebhooks, in: channel.id), "Admins should be able to do anything")
        XCTAssertTrue(permissionsTestGuild.canMember(permissionsTestMembers[2], .manageRoles, in: channel.id), "Users should be able to do things allowed by their roles")
        XCTAssertFalse(permissionsTestGuild.canMember(permissionsTestMembers[4], .manageRoles, in: channel.id), "Users should not be able to do things not allowed by their roles")
    }

    func testRoleOverrides() {
        let channel = createPermissionTestChannel(overwrites: roleOverwrites)

        XCTAssertEqual(channel.permissionOverwrites?.count, roleOverwrites.count, "There should be the same number of permission overwrites in this channel as we put in")

        XCTAssertFalse(permissionsTestGuild.canMember(permissionsTestMembers[2], .readMessageHistory, in: channel.id), "@everyone role should be applied to all members")
        XCTAssertTrue(permissionsTestGuild.canMember(permissionsTestMembers[2], .viewAuditLog, in: channel.id), "@everyone role should be applied to all members")
        XCTAssertFalse(permissionsTestGuild.canMember(permissionsTestMembers[4], .viewAuditLog, in: channel.id), "@everyone permission should be overridden by permissions for a specific role")
        XCTAssertTrue(permissionsTestGuild.canMember(permissionsTestMembers[0], .sendMessages, in: channel.id), "Owner should override all permissions")
        XCTAssertTrue(permissionsTestGuild.canMember(permissionsTestMembers[1], .viewChannel, in: channel.id), "Admin role should override all permissions")
        XCTAssertTrue(permissionsTestGuild.canMember(permissionsTestMembers[4], .addReactions, in: channel.id), "An allow override should go over a deny of the same type")
        XCTAssertTrue(permissionsTestGuild.canMember(permissionsTestMembers[3], .addReactions, in: channel.id), "An allow override should go over a deny of the same type even if the deny is higher on the list")
        XCTAssertFalse(permissionsTestGuild.canMember(permissionsTestMembers[4], .sendMessages, in: channel.id), "A role permission deny should be properly applied to a normal user")
        XCTAssertFalse(permissionsTestGuild.canMember(permissionsTestMembers[2], .addReactions, in: channel.id), "A role permission deny should be properly applied to a normal user")
    }

    func testUserOverrides() {
        let channel = createPermissionTestChannel(overwrites: userOverwrites + roleOverwrites)

        XCTAssertEqual(channel.permissionOverwrites?.count, roleOverwrites.count + userOverwrites.count, "There should be the same number of permission overwrites in this channel as we put in")

        XCTAssertTrue(permissionsTestGuild.canMember(permissionsTestMembers[0], .manageMessages, in: channel.id), "Owner should override all permissions")
        XCTAssertTrue(permissionsTestGuild.canMember(permissionsTestMembers[1], .manageWebhooks, in: channel.id), "Admin role should override all permissions")
        XCTAssertTrue(permissionsTestGuild.canMember(permissionsTestMembers[2], .addReactions, in: channel.id), "User permissions should override role permissions")
        XCTAssertFalse(permissionsTestGuild.canMember(permissionsTestMembers[2], .manageMessages, in: channel.id), "A user permission deny should be properly applied to a normal user")
        XCTAssertFalse(permissionsTestGuild.canMember(permissionsTestMembers[3], .addReactions, in: channel.id), "User permissions should override role permissions that overrode other role permissions")
        XCTAssertTrue(permissionsTestGuild.canMember(permissionsTestMembers[4], .embedLinks, in: channel.id), "User permissions should be properly applied to a normal user")
        XCTAssertTrue(permissionsTestGuild.canMember(permissionsTestMembers[4], .sendMessages, in: channel.id), "A user allow should override a role deny")
    }

    func testOverwritesWithDependencies() {
        let channel = createPermissionTestChannel(overwrites: depencencyOverwrites)

        XCTAssertEqual(channel.permissionOverwrites?.count, depencencyOverwrites.count, "There should be the same number of permission overwrites in this channel as we put in")

        XCTAssertFalse(permissionsTestGuild.canMember(permissionsTestMembers[4], .sendMessages, in: channel.id), "A user who can't read messages shouldn't be able to send them")
        XCTAssertEqual(permissionsTestGuild.permissions(for: permissionsTestMembers[4], in: channel.id)!.intersection([.createInstantInvite, .manageChannels, .addReactions, .sendMessages, .sendTTSMessages, .manageMessages, .embedLinks, .attachFiles, .readMessageHistory, .mentionEveryone, .useExternalEmojis]), [], "A user who can't read messages shouldn't be able to do any channel-related things")
        XCTAssertFalse(permissionsTestGuild.canMember(permissionsTestMembers[4], .sendTTSMessages, in: channel.id), "A user who can't send messages shouldn't be able to send TTS messages")
        XCTAssertTrue(permissionsTestGuild.canMember(permissionsTestMembers[3], .sendMessages, in: channel.id), "A user who has conflicting read messages permissions where the allow is used shouldn't have dependencies blocked")
        XCTAssertEqual(permissionsTestGuild.permissions(for: permissionsTestMembers[2], in: channel.id)!.intersection([.sendTTSMessages, .embedLinks, .attachFiles, .mentionEveryone]), [], "A user who can't send messages shouldn't be able to send TTS messages, embed links, attach files, or mention everyone")
    }

    let roleOverwrites = [
        DiscordPermissionOverwrite(id: permissionsTestGuild.id, type: .role, allow: .viewAuditLog, deny: .readMessageHistory),
        DiscordPermissionOverwrite(id: permissionsTestRoles[3].id, type: .role, allow: [], deny: [.sendMessages, .addReactions, .viewAuditLog]),
        DiscordPermissionOverwrite(id: permissionsTestRoles[2].id, type: .role, allow: .addReactions, deny: []),
        DiscordPermissionOverwrite(id: permissionsTestRoles[0].id, type: .role, allow: [], deny: .viewChannel),
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
        DiscordPermissionOverwrite(id: permissionsTestRoles[2].id, type: .role, allow: [], deny: .viewChannel),
        DiscordPermissionOverwrite(id: permissionsTestUsers[4].id, type: .member, allow: [.createInstantInvite, .manageChannels, .addReactions, .sendMessages, .sendTTSMessages, .manageMessages, .embedLinks, .attachFiles, .readMessageHistory, .mentionEveryone, .useExternalEmojis], deny: []),
        DiscordPermissionOverwrite(id: permissionsTestUsers[3].id, type: .member, allow: .viewChannel, deny: []),
        DiscordPermissionOverwrite(id: permissionsTestUsers[2].id, type: .member, allow: [.sendTTSMessages, .embedLinks, .attachFiles, .mentionEveryone], deny: .sendMessages)
    ]

    public override func setUp() {
        permissionsTestClient.handleDispatch(event: .guildCreate(permissionsTestGuild))
    }

    public override func tearDown() {
        permissionsTestClient.handleDispatch(event: .guildDelete(permissionsTestGuild))
        XCTAssertEqual(permissionsTestClient.channelCache.count, 0, "Removing guild should clear its channels from the channel cache")
    }
}

let permissionsTestUsers = ["23416345", "32564235", "4359835345", "32499342123", "234234120985"].map({ id -> DiscordUser in
    var tmp = testUser
    tmp.id = .init(id)!
    return tmp
})

let permissionsTestUserPermissions: DiscordPermissions = [.createInstantInvite, .addReactions, .viewChannel, .sendMessages, .readMessageHistory, .useExternalEmojis, .connect, .speak, .useVAD, .changeNickname]
let permissionsTestRoles: [DiscordRole] = [
    DiscordRole(id: 2349683489545, color: 10181046, hoist: true, managed: false, mentionable: true, name: "Admin", permissions: .administrator, position: 3),
    DiscordRole(id: 32423425264343, color: 10718666, hoist: true, managed: false, mentionable: true, name: "Mod", permissions: permissionsTestUserPermissions.union([.kickMembers, .manageChannels, .viewAuditLog, .sendTTSMessages, .embedLinks, .attachFiles, .mentionEveryone, .muteMembers, .deafenMembers, .moveMembers, .manageNicknames, .manageRoles]), position: 2),
    DiscordRole(id: 34634634534564, color: 567526, hoist: true, managed: false, mentionable: true, name: "Test", permissions: permissionsTestUserPermissions, position: 1),
    DiscordRole(id: 34029736498534, color: 0, hoist: false, managed: false, mentionable: false, name: "Muted", permissions: permissionsTestUserPermissions, position: 0)
]

class PermissionsTestClientDelegate: DiscordClientDelegate { }
let permissionsTestClientDelegate = PermissionsTestClientDelegate()
let permissionsTestClient = DiscordClient(token: "Testing", delegate: permissionsTestClientDelegate)

let permissionsTestGuild = { () -> DiscordGuild in
    var tmp = testGuild
    tmp.ownerId = permissionsTestUsers[0].id
    tmp.roles = .init(permissionsTestRoles)
    return roundTripEncode(tmp)
}()

let permissionTestMemberRoles: [[RoleID]] = [
    [permissionsTestRoles[3].id],
    [permissionsTestRoles[0].id, permissionsTestRoles[2].id],
    [permissionsTestRoles[1].id],
    [permissionsTestRoles[1].id, permissionsTestRoles[2].id],
    [permissionsTestRoles[2].id, permissionsTestRoles[3].id]
]

let permissionsTestMembers = zip(permissionsTestUsers, permissionTestMemberRoles).map({zipped -> DiscordGuildMember in
    let (user, roles) = zipped
    
    return DiscordGuildMember(guildId: permissionsTestGuild.id, user: user, deaf: false, mute: false, nick: nil, roleIds: roles, joinedAt: DiscordDateFormatter.format("2017-04-25T20:00:00.000000+00:00")!)
})

func createPermissionTestChannel(overwrites: [DiscordPermissionOverwrite]) -> DiscordChannel {
    var channelData = testGuildTextChannel
    channelData.permissionOverwrites = .init(overwrites)
    channelData.guildId = permissionsTestGuild.id
    channelData = roundTripEncode(channelData)
    permissionsTestClient.handleDispatch(event: .channelCreate(channelData))
    return permissionsTestClient.findChannel(fromId: channelData.id)!
}
