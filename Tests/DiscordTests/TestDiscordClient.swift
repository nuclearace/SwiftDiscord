//
// Created by Erik Little on 3/26/17.
//

import Foundation
import XCTest
@testable import Discord

public class TestDiscordClient : XCTestCase, DiscordClientDelegate {
    func testClientCreatesGuild() {
        expectations[.guildCreate] = expectation(description: "Client should call guild create method")

        client.handleDispatch(event: .guildCreate, data: .object(testGuildJSON))

        waitForExpectations(timeout: 0.2)
    }

    func testClientUpdatesGuild() {
        expectations[.guildCreate] = expectation(description: "Client should call guild create method")
        expectations[.guildUpdate] = expectation(description: "Client should call guild update method")

        let updateJSON: [String: Any] = [
            "id": "100",
            "name": "A new name"
        ]

        client.handleDispatch(event: .guildCreate, data: .object(testGuildJSON))
        client.handleDispatch(event: .guildUpdate, data: .object(updateJSON))

        waitForExpectations(timeout: 0.2)
    }

    func testClientDeletesGuild() {
        expectations[.guildCreate] = expectation(description: "Client should call guild create method")
        expectations[.guildDelete] = expectation(description: "Client should call guild delete method")

        client.handleDispatch(event: .guildCreate, data: .object(testGuildJSON))

        // Force guild's channels into the channel cache
        for channel in (testGuildJSON["channels"] as! [[String: Any]]).map({ Snowflake($0["id"] as! String)! }) {
            _ = client.findChannel(fromId: channel)
        }

        client.handleDispatch(event: .guildDelete, data: .object(["id": "100"]))

        waitForExpectations(timeout: 0.2)
    }

    func testClientHandlesGuildMemberAdd() {
        expectations[.guildCreate] = expectation(description: "Client should call guild create method")
        expectations[.guildMemberAdd] = expectation(description: "Client should call guild member add method")

        var tMember = testMember
        var tUser = testUser

        tUser["id"] = "30"
        tMember["guild_id"] = "100"
        tMember["user"] = tUser
        tMember["nick"] = "test nick"

        client.handleDispatch(event: .guildCreate, data: .object(testGuildJSON))
        client.handleDispatch(event: .guildMemberAdd, data: .object(tMember))

        waitForExpectations(timeout: 0.2)
    }

    func testClientHandlesGuildMemberUpdate() {
        expectations[.guildCreate] = expectation(description: "Client should call guild member update method")
        expectations[.guildMemberUpdate] = expectation(description: "Client should call guild member update method")

        var tMember = testMember
        var tUser = testUser

        tUser["id"] = "15"
        tMember["guild_id"] = "100"
        tMember["user"] = tUser
        tMember["nick"] = "a new nick"

        client.handleDispatch(event: .guildCreate, data: .object(testGuildJSON))
        client.handleDispatch(event: .guildMemberUpdate, data: .object(tMember))

        waitForExpectations(timeout: 0.2)
    }

    func testClientHandlesGuildMemberRemove() {
        expectations[.guildCreate] = expectation(description: "Client should call guild member remove method")
        expectations[.guildMemberRemove] = expectation(description: "Client should call guild member remove method")

        var tMember = testMember
        var tUser = testUser

        tUser["id"] = "15"
        tMember["guild_id"] = "100"
        tMember["user"] = tUser

        client.handleDispatch(event: .guildCreate, data: .object(testGuildJSON))
        client.handleDispatch(event: .guildMemberRemove, data: .object(tMember))

        waitForExpectations(timeout: 0.2)
    }

    func testClientCreatesGuildChannel() {
        expectations[.guildCreate] = expectation(description: "Client should call guild member remove method")
        expectations[.channelCreate] = expectation(description: "Client should call create create method")

        var tChannel = testGuildTextChannel

        tChannel["id"] = "205"
        tChannel["name"] = "A new channel"

        client.handleDispatch(event: .guildCreate, data: .object(testGuildJSON))
        client.handleDispatch(event: .channelCreate, data: .object(tChannel))

        waitForExpectations(timeout: 0.2)
    }

    func testClientCreatesDMChannel() {
        expectations[.channelCreate] = expectation(description: "Client should call create create method")

        client.handleDispatch(event: .channelCreate, data: .object(testDMChannel))

        waitForExpectations(timeout: 0.2)
    }

    func testClientCreatesGroupDMChannel() {
        expectations[.channelCreate] = expectation(description: "Client should call create create method")

        client.handleDispatch(event: .channelCreate, data: .object(testGroupDMChannel))

        waitForExpectations(timeout: 0.2)
    }

    func testClientDeletesGuildChannel() {
        expectations[.guildCreate] = expectation(description: "Client should call guild member remove method")
        expectations[.channelCreate] = expectation(description: "Client should call channel create method")
        expectations[.channelDelete] = expectation(description: "Client should call delete channel method")

        var tChannel = testGuildTextChannel

        tChannel["id"] = "205"
        tChannel["name"] = "A new channel"

        client.handleDispatch(event: .guildCreate, data: .object(testGuildJSON))
        client.handleDispatch(event: .channelCreate, data: .object(tChannel))
        client.handleDispatch(event: .channelDelete, data: .object(tChannel))

        waitForExpectations(timeout: 0.2)
    }

    func testClientDeletesGuildChannelCategory() {
        expectations[.guildCreate] = expectation(description: "Client should call guild member remove method")
        expectations[.channelCreate] = expectation(description: "Client should call channel create method")
        expectations[.channelDelete] = expectation(description: "Client should call delete channel method")

        var tChannel = testGuildChannelCategory

        tChannel["id"] = "205"

        client.handleDispatch(event: .guildCreate, data: .object(testGuildJSON))
        client.handleDispatch(event: .channelCreate, data: .object(tChannel))
        client.handleDispatch(event: .channelDelete, data: .object(tChannel))

        waitForExpectations(timeout: 0.2)
    }

    func testClientDeletesDirectChannel() {
        expectations[.channelCreate] = expectation(description: "Client should call channel create method")
        expectations[.channelDelete] = expectation(description: "Client should call channel delete method")

        client.handleDispatch(event: .channelCreate, data: .object(testDMChannel))
        client.handleDispatch(event: .channelDelete, data: .object(testDMChannel))

        waitForExpectations(timeout: 0.2)
    }

    func testClientDeletesGroupDMChannel() {
        expectations[.channelCreate] = expectation(description: "Client should call create create method")
        expectations[.channelDelete] = expectation(description: "Client should call channel delete method")

        client.handleDispatch(event: .channelCreate, data: .object(testGroupDMChannel))
        client.handleDispatch(event: .channelDelete, data: .object(testGroupDMChannel))

        waitForExpectations(timeout: 0.2)
    }

    func testClientUpdatesGuildChannel() {
        expectations[.guildCreate] = expectation(description: "Client should call guild member remove method")
        expectations[.channelUpdate] = expectation(description: "Client should call update channel method")

        var tChannel = testGuildTextChannel

        tChannel["name"] = "A new channel"

        client.handleDispatch(event: .guildCreate, data: .object(testGuildJSON))
        client.handleDispatch(event: .channelUpdate, data: .object(tChannel))

        waitForExpectations(timeout: 0.2)
    }

    func testClientUpdatesGuildChannelCategory() {
        expectations[.guildCreate] = expectation(description: "Client should call guild member remove method")
        expectations[.channelCreate] = expectation(description: "Client should create a category channel")
        expectations[.channelUpdate] = expectation(description: "Client should call update channel method")

        var tChannel = testGuildChannelCategory

        tChannel["id"] = "205"
        tChannel["name"] = "A new channel"

        client.handleDispatch(event: .guildCreate, data: .object(testGuildJSON))
        client.handleDispatch(event: .channelCreate, data: .object(tChannel))
        client.handleDispatch(event: .channelUpdate, data: .object(tChannel))

        waitForExpectations(timeout: 0.2)
    }

    func testClientHandlesGuildEmojiUpdate() {
        expectations[.guildCreate] = expectation(description: "Client should call guild member remove method")
        expectations[.guildEmojisUpdate] = expectation(description: "Client should call guild emoji update method")

        let emojiUpdate: [String: Any] = [
            "guild_id": "100",
            "emojis": createEmojiObjects(n: 20)
        ]

        client.handleDispatch(event: .guildCreate, data: .object(testGuildJSON))
        client.handleDispatch(event: .guildEmojisUpdate, data: .object(emojiUpdate))

        waitForExpectations(timeout: 0.2)
    }

    func testClientHandlesRoleCreate() {
        expectations[.guildCreate] = expectation(description: "Client should call guild member remove method")
        expectations[.guildRoleCreate] = expectation(description: "Client should call guild role create method")

        let roleCreate: [String: Any] = [
            "guild_id": "100",
            "role": testRole
        ]

        client.handleDispatch(event: .guildCreate, data: .object(testGuildJSON))
        client.handleDispatch(event: .guildRoleCreate, data: .object(roleCreate))

        waitForExpectations(timeout: 0.2)
    }

    func testClientHandlesRoleUpdate() {
        expectations[.guildCreate] = expectation(description: "Client should call guild member remove method")
        expectations[.guildRoleCreate] = expectation(description: "Client should call guild role create method")
        expectations[.guildRoleUpdate] = expectation(description: "Client should call guild role update method")

        var tRole = testRole
        var roleUpdate: [String: Any] = [
            "guild_id": "100",
            "role": testRole
        ]

        client.handleDispatch(event: .guildCreate, data: .object(testGuildJSON))
        client.handleDispatch(event: .guildRoleCreate, data: .object(roleUpdate))

        tRole["name"] = "A dank role"
        roleUpdate["role"] = tRole

        client.handleDispatch(event: .guildRoleUpdate, data: .object(roleUpdate))

        waitForExpectations(timeout: 0.2)
    }

    func testClientHandlesRoleRemove() {
        expectations[.guildCreate] = expectation(description: "Client should call guild member remove method")
        expectations[.guildRoleCreate] = expectation(description: "Client should call guild role create method")
        expectations[.guildRoleDelete] = expectation(description: "Client should call guild role delete method")

        let roleCreate: [String: Any] = [
            "guild_id": "100",
            "role": testRole
        ]

        let roleDelete: [String: Any] = [
            "guild_id": "100",
            "role_id": "400"
        ]

        client.handleDispatch(event: .guildCreate, data: .object(testGuildJSON))
        client.handleDispatch(event: .guildRoleCreate, data: .object(roleCreate))
        client.handleDispatch(event: .guildRoleDelete, data: .object(roleDelete))

        waitForExpectations(timeout: 0.2)
    }

    func testClientCallsUnhandledEventMethod() {
        expectations[.typingStart] = expectation(description: "Client should call the unhandled event method")

        client.handleDispatch(event: .typingStart, data: .object([:]))

        waitForExpectations(timeout: 0.2)
    }

    func testClientFindsGuildTextChannel() {
        expectations[.guildCreate] = expectation(description: "Client should call guild create method")

        client.handleDispatch(event: .guildCreate, data: .object(testGuildJSON))

        assertFindChannel(channelFixture: testGuildTextChannel, channelType: DiscordGuildTextChannel.self)

        waitForExpectations(timeout: 0.2)
    }

    func testClientFindsGuildVoiceChannel() {
        expectations[.guildCreate] = expectation(description: "Client should call guild create method")

        client.handleDispatch(event: .guildCreate, data: .object(testGuildJSON))

        assertFindChannel(channelFixture: testGuildVoiceChannel, channelType: DiscordGuildVoiceChannel.self)

        waitForExpectations(timeout: 0.2)
    }

    func testClientFindsDirectChannel() {
        expectations[.channelCreate] = expectation(description: "Client should call guild create method")

        client.handleDispatch(event: .channelCreate, data: .object(testDMChannel))

        assertFindChannel(channelFixture: testDMChannel, channelType: DiscordDMChannel.self)

        waitForExpectations(timeout: 0.2)
    }

    func testClientFindsGroupDMChannel() {
        expectations[.channelCreate] = expectation(description: "Client should call guild create method")

        client.handleDispatch(event: .channelCreate, data: .object(testGroupDMChannel))

        assertFindChannel(channelFixture: testDMChannel, channelType: DiscordGroupDMChannel.self)

        waitForExpectations(timeout: 0.2)
    }

    func testClientCorrectlyAddsPresenceToGuild() {
        expectations[.guildCreate] = expectation(description: "Client should call guild create method")
        expectations[.presenceUpdate] = expectation(description: "Client should call presence update method")

        client.handleDispatch(event: .guildCreate, data: .object(testGuildJSON))
        client.handleDispatch(event: .presenceUpdate, data: .object(testPresence))

        waitForExpectations(timeout: 0.2)
    }

    func testClientCorrectlyCreatesMessage() {
        expectations[.messageCreate] = expectation(description: "Client should call the message create method")

        client.handleDispatch(event: .messageCreate, data: .object(testMessage))

        waitForExpectations(timeout: 0.2)
    }

    var client: DiscordClient!
    var expectations = [DiscordDispatchEvent: XCTestExpectation]()

    public static var allTests: [(String, (TestDiscordClient) -> () -> ())] {
        return [
            ("testClientCreatesGuild", testClientCreatesGuild),
            ("testClientUpdatesGuild", testClientUpdatesGuild),
            ("testClientDeletesGuild", testClientDeletesGuild),
            ("testClientHandlesGuildMemberAdd", testClientHandlesGuildMemberAdd),
            ("testClientHandlesGuildMemberUpdate", testClientHandlesGuildMemberUpdate),
            ("testClientHandlesGuildMemberRemove", testClientHandlesGuildMemberRemove),
            ("testClientCreatesGuildChannel", testClientCreatesGuildChannel),
            ("testClientCreatesDMChannel", testClientCreatesDMChannel),
            ("testClientCreatesGroupDMChannel", testClientCreatesGroupDMChannel),
            ("testClientDeletesGuildChannel", testClientDeletesGuildChannel),
            ("testClientDeletesGuildCategoryChannel", testClientDeletesGuildChannelCategory),
            ("testClientDeletesDirectChannel", testClientDeletesDirectChannel),
            ("testClientDeletesGroupDMChannel", testClientDeletesGroupDMChannel),
            ("testClientUpdatesGuildChannel", testClientUpdatesGuildChannel),
            ("testClientUpdatesGuildChannelCategory", testClientUpdatesGuildChannelCategory),
            ("testClientHandlesGuildEmojiUpdate", testClientHandlesGuildEmojiUpdate),
            ("testClientHandlesRoleCreate", testClientHandlesRoleCreate),
            ("testClientHandlesRoleUpdate", testClientHandlesRoleUpdate),
            ("testClientHandlesRoleRemove", testClientHandlesRoleRemove),
            ("testClientCallsUnhandledEventMethod", testClientCallsUnhandledEventMethod),
            ("testClientFindsGuildTextChannel", testClientFindsGuildTextChannel),
            ("testClientFindsGuildVoiceChannel", testClientFindsGuildVoiceChannel),
            ("testClientFindsDirectChannel", testClientFindsDirectChannel),
            ("testClientFindsGroupDMChannel", testClientFindsGroupDMChannel),
            ("testClientCorrectlyAddsPresenceToGuild", testClientCorrectlyAddsPresenceToGuild),
            ("testClientCorrectlyCreatesMessage", testClientCorrectlyCreatesMessage)
        ]
    }

    public override func setUp() {
        client = DiscordClient(token: "Testing", delegate: self)
        expectations = [DiscordDispatchEvent: XCTestExpectation]()
    }
}

extension TestDiscordClient {
    // MARK: Channel testing

    enum ChannelTestType {
        case create
        case delete
    }

    func assertGuildChannel(_ channel: DiscordGuildChannel, expectedGuildChannels expected: Int,
                            testType type: ChannelTestType) {
        guard let clientGuild = client.guilds[channel.guildId] else {
            XCTFail("Guild for channel should be in guilds")

            return
        }

        switch type {
        case .create:
            XCTAssertEqual(clientGuild.channels[channel.id]?.id, channel.id, "Channels should be the same")
        case .delete:
            XCTAssertNil(clientGuild.channels[channel.id], "Channel should be removed from guild")
        }

        XCTAssertEqual(clientGuild.channels.count, expected, "Number of channels should be predictable")
    }

    func assertDMChannel(_ channel: DiscordDMChannel, testType type: ChannelTestType) {
        switch type {
        case .create:
            XCTAssertNotNil(client.directChannels[channel.id], "Created DM Channel should be in direct channels")
        case .delete:
            XCTAssertNil(client.directChannels[channel.id], "Deleted DM Channel should not be in direct channels")
        }

        XCTAssertEqual(channel.id, Snowflake(testUser["id"] as! String)!, "Channel create should index channels by "
                                                              + "recipient id")
    }

    func assertGroupDMChannel(_ channel: DiscordGroupDMChannel, testType type: ChannelTestType) {
        switch type {
        case .create:
            XCTAssertNotNil(client.directChannels[channel.id], "Created Group DM Channel should be in direct channels")
        case .delete:
            XCTAssertNil(client.directChannels[channel.id], "Deleted Group DM Channel should not be in direct channels")
        }

        XCTAssertEqual(channel.name, "A Group DM", "Channel create should index channels by recipient id")
    }

    func assertFindChannel<T: DiscordChannel>(channelFixture: [String: Any], channelType: T.Type) {
        guard let channel = client.findChannel(fromId: Snowflake(channelFixture["id"] as! String)!) as? T else {
            XCTFail("Client did not find channel")

            return
        }

        XCTAssertEqual(channel.id, Snowflake(channelFixture["id"] as! String)!, "findChannel should find the correct channel")
        XCTAssertNotNil(client.channelCache[channel.id], "Found channel should be in cache")
    }
}

public extension TestDiscordClient {
    // MARK: DiscordClientDelegate

    func client(_ client: DiscordClient, didCreateChannel channel: DiscordChannel) {
        switch channel {
        case let guildChannel as DiscordGuildChannel:
            assertGuildChannel(guildChannel, expectedGuildChannels: 3, testType: .create)
        case let dmChannel as DiscordDMChannel:
            assertDMChannel(dmChannel, testType: .create)
        case let groupDmChannel as DiscordGroupDMChannel:
            assertGroupDMChannel(groupDmChannel, testType: .create)
        default:
            XCTFail("Unknown channel type")
        }

        expectations[.channelCreate]?.fulfill()
    }

    func client(_ client: DiscordClient, didDeleteChannel channel: DiscordChannel) {
        switch channel {
        case let guildChannel as DiscordGuildChannel:
            assertGuildChannel(guildChannel, expectedGuildChannels: 2, testType: .delete)
        case let dmChannel as DiscordDMChannel:
            assertDMChannel(dmChannel, testType: .delete)
        case let groupDmChannel as DiscordGroupDMChannel:
            assertGroupDMChannel(groupDmChannel, testType: .delete)
        default:
            XCTFail("Unknown channel type")
        }

        expectations[.channelDelete]?.fulfill()
    }

    func client(_ client: DiscordClient, didUpdateChannel channel: DiscordChannel) {
        guard let guildChannel = channel as? DiscordGuildChannel else {
            XCTFail("Updated channel is not a guild channel")

            return
        }

        guard let clientGuild = client.guilds[guildChannel.guildId] else {
            XCTFail("Guild for channel should be in guilds")

            return
        }

        switch guildChannel {
        case is DiscordGuildChannelCategory:
            XCTAssertEqual(clientGuild.channels.count, 3, "Guild should have three channels")
            XCTAssertEqual(guildChannel.name, "A new channel", "A new channel should have been updated")
        default:
            XCTAssertEqual(clientGuild.channels.count, 2, "Guild should have two channels")
            XCTAssertEqual(guildChannel.name, "A new channel", "A new channel should have been updated")
        }

        expectations[.channelUpdate]?.fulfill()
    }

    func client(_ client: DiscordClient, didAddGuildMember member: DiscordGuildMember) {
        guard let clientGuild = client.guilds[member.guildId] else {
            XCTFail("Guild for member should be in guilds")

            return
        }

        XCTAssertEqual(member.nick, "test nick", "Guild member add should correctly create a member")
        XCTAssertNotNil(clientGuild.members[member.user.id], "Member should be in guild after being added")
        XCTAssertEqual(clientGuild.members.count, 21, "Guild member add should correctly add a new member to members")
        XCTAssertEqual(clientGuild.memberCount, 21, "Guild member add should correctly increment the number of members")

        expectations[.guildMemberAdd]?.fulfill()
    }

    func client(_ client: DiscordClient, didRemoveGuildMember member: DiscordGuildMember) {
        guard let clientGuild = client.guilds[member.guildId] else {
            XCTFail("Guild for member should be in guilds")

            return
        }

        XCTAssertNil(clientGuild.members[member.user.id], "Guild member remove should remove member")
        XCTAssertEqual(clientGuild.members.count, 19, "Guild member remove should correctly remove a member")
        XCTAssertEqual(clientGuild.memberCount, 19, "Guild member remove should correctly decrement the number of members")

        expectations[.guildMemberRemove]?.fulfill()
    }

    func client(_ client: DiscordClient, didUpdateGuildMember member: DiscordGuildMember) {
        guard let guildMember = client.guilds[member.guildId]?.members[member.user.id] else {
            XCTFail("Guild member should be in guild")

            return
        }

        XCTAssertEqual(guildMember.nick, "a new nick", "Member on guild should be updated")

        expectations[.guildMemberUpdate]?.fulfill()
    }

    func client(_ client: DiscordClient, didCreateGuild guild: DiscordGuild) {
        guard let clientGuild = client.guilds[guild.id] else {
            XCTFail("Guild should be in guilds")

            return
        }

        XCTAssertEqual(clientGuild.channels.count, 2, "Created guild should have two channels")
        XCTAssertEqual(clientGuild.members.count, 20, "Created guild should have 20 members")
        XCTAssertEqual(clientGuild.presences.count, 20, "Created guild should have 20 presences")
        XCTAssert(guild === clientGuild, "Guild on the client should be the same as one passed to handler")

        expectations[.guildCreate]?.fulfill()
    }

    func client(_ client: DiscordClient, didDeleteGuild guild: DiscordGuild) {
        XCTAssertEqual(client.guilds.count, 0, "Client should have no guilds")
        for channel in guild.channels.keys {
            XCTAssertNil(client.channelCache[channel], "Removing a guild should remove its channels from the channel cache")
        }
        XCTAssertEqual(guild.id, 100, "Test guild should be removed")

        expectations[.guildDelete]?.fulfill()
    }

    func client(_ client: DiscordClient, didUpdateGuild guild: DiscordGuild) {
        guard let clientGuild = client.guilds[guild.id] else {
            XCTFail("Guild should be in guilds")

            return
        }

        XCTAssertEqual(clientGuild.name, "A new name", "Guild should correctly update name")
        XCTAssert(guild === clientGuild, "Guild on the client should be the same as one passed to handler")

        expectations[.guildUpdate]?.fulfill()
    }

    func client(_ client: DiscordClient, didUpdateEmojis emojis: [EmojiID: DiscordEmoji],
                onGuild guild: DiscordGuild) {
        XCTAssertEqual(guild.emojis.count, 20, "Update should have 20 emoji")

        expectations[.guildEmojisUpdate]?.fulfill()
    }

    func client(_ client: DiscordClient, didCreateMessage message: DiscordMessage) {
        XCTAssertEqual(message.content, testMessage["content"] as! String, "Message content should be the same")
        XCTAssertEqual(message.channelId, Snowflake(testMessage["channel_id"] as! String)!, "Channel id should be the same")

        expectations[.messageCreate]?.fulfill()
    }

    func client(_ client: DiscordClient, didReceivePresenceUpdate presence: DiscordPresence) {
        XCTAssertEqual(presence.user.id, Snowflake(testUser["id"] as! String)!, "Presence should be for the test user")
        XCTAssertNotNil(client.guilds[presence.guildId]?.presences[presence.user.id])

        expectations[.presenceUpdate]?.fulfill()
    }

    func client(_ client: DiscordClient, didCreateRole role: DiscordRole, onGuild guild: DiscordGuild) {
        guard let clientGuild = client.guilds[guild.id] else {
            XCTFail("Guild should be in guilds")

            return
        }

        XCTAssertNotNil(clientGuild.roles[role.id], "Role should be in guild")
        XCTAssertEqual(role.name, "My Test Role", "Role create should correctly make role")

        expectations[.guildRoleCreate]?.fulfill()
    }

    func client(_ client: DiscordClient, didDeleteRole role: DiscordRole, fromGuild guild: DiscordGuild) {
        guard let clientGuild = client.guilds[guild.id] else {
            XCTFail("Guild should be in guilds")

            return
        }

        XCTAssertNil(clientGuild.roles[role.id], "Role should not be in guild")
        XCTAssertEqual(role.name, "My Test Role", "Role create should correctly make role")

        expectations[.guildRoleDelete]?.fulfill()
    }

    func client(_ client: DiscordClient, didUpdateRole role: DiscordRole, onGuild guild: DiscordGuild) {
        guard let clientGuild = client.guilds[guild.id] else {
            XCTFail("Guild should be in guilds")

            return
        }

        XCTAssertNotNil(clientGuild.roles[role.id], "Role should be in guild")
        XCTAssertEqual(role.name, "A dank role", "Role create should correctly update role")

        expectations[.guildRoleUpdate]?.fulfill()
    }

    func client(_ client: DiscordClient, didNotHandleDispatchEvent event: DiscordDispatchEvent,
                withData data: [String: Any]) {
        expectations[.typingStart]?.fulfill()
    }

}
