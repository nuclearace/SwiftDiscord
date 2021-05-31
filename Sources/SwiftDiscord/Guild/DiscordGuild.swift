// The MIT License (MIT)
// Copyright (c) 2016 Erik Little

// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated
// documentation files (the "Software"), to deal in the Software without restriction, including without
// limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the
// Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

// The above copyright notice and this permission notice shall be included in all copies or substantial portions of the
// Software.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING
// BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO
// EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
// ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
// DEALINGS IN THE SOFTWARE.

import class Dispatch.DispatchSemaphore
import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import Logging

fileprivate let logger = Logger(label: "DiscordGuild")

/// Represents a Guild.
public final class DiscordGuild : DiscordClientHolder, CustomStringConvertible {
    // MARK: Properties

    // TODO figure out what features are
    /// The guild's features.
    public let features: [Any]

    /// The snowflake id of the guild.
    public let id: GuildID

    /// Whether or not this a "large" guild.
    public let large: Bool

    /// The date the user joined the guild.
    public let joinedAt: Date

    /// The base64 encoded splash image.
    public let splash: String

    /// Whether this guild is unavailable.
    public let unavailable: Bool

    /// - returns: A description of this guild
    public var description: String {
        return "DiscordGuild(name: \(name))"
    }

    /// A `DiscordLazyDictionary` of guild members. The key is the snowflake id of the user.
    public var members = DiscordLazyDictionary<UserID, DiscordGuildMember>()

    /// Reference to the client.
    public weak var client: DiscordClient?

    /// A dictionary of this guild's channels. The key is the snowflake id of the channel.
    public internal(set) var channels: [ChannelID: DiscordGuildChannel]

    /// A dictionary of this guild's emojis. The key is the snowflake id of the emoji.
    public internal(set) var emojis: [EmojiID: DiscordEmoji]

    /// The number of members in this guild.
    ///
    /// *This number might not be the actual number of users in the `members` field.*
    public internal(set) var memberCount: Int

    /// A `DiscordLazyDictionary` of presences. The key is the snowflake id of the user.
    public internal(set) var presences = DiscordLazyDictionary<UserID, DiscordPresence>()

    /// A dictionary of this guild's roles. The key is the snowflake id of the role.
    public internal(set) var roles: [RoleID: DiscordRole]

    /// A dictionary of this guild's current voice states. The key is the snowflake id of the user for this voice
    /// state.
    public internal(set) var voiceStates: [UserID: DiscordVoiceState]

    /// The default message notification setting.
    public private(set) var defaultMessageNotifications: Int

    /// The snowflake id of the embed channel for this guild.
    public private(set) var widgetChannelId: ChannelID

    /// Whether this guild has embed enabled.
    public private(set) var widgetEnabled: Bool

    /// The base64 encoded icon image for this guild.
    public private(set) var icon: String

    /// The base64 encoded banner image for this guild.
    public private(set) var banner: String

    /// The multi-factor authentication level for this guild.
    public private(set) var mfaLevel: Int

    /// The name of this guild.
    public private(set) var name: String

    /// The snowflake id of this guild's owner.
    public private(set) var ownerId: UserID

    /// The region this guild is in.
    public private(set) var region: String

    /// The verification level a member of this guild must have to join.
    public private(set) var verificationLevel: Int

    init(guildObject: [String: Any], client: DiscordClient?) {
        id = guildObject.getSnowflake()
        channels = guildChannels(fromArray: guildObject.get("channels", or: JSONArray()), guildID: id, client: client)
        defaultMessageNotifications = guildObject.get("default_message_notifications", or: -1)
        widgetEnabled = guildObject.get("widget_enabled", or: false)
        widgetChannelId = guildObject.getSnowflake(key: "widget_channel_id")
        emojis = DiscordEmoji.emojisFromArray(guildObject.get("emojis", or: JSONArray()))
        features = guildObject.get("features", or: Array<Any>())
        icon = guildObject.get("icon", or: "")
        banner = guildObject.get("banner", or: "")
        large = guildObject.get("large", or: false)
        memberCount = guildObject.get("member_count", or: 0)
        mfaLevel = guildObject.get("mfa_level", or: -1)
        name = guildObject.get("name", or: "")
        ownerId = guildObject.getSnowflake(key: "owner_id")

        if !(client?.discardPresences ?? false) {
            presences = DiscordPresence.presencesFromArray(guildObject.get("presences", or: JSONArray()), guildId: id)
        }

        region = guildObject.get("region", or: "")
        roles = DiscordRole.rolesFromArray(guildObject.get("roles", or: JSONArray()))
        splash = guildObject.get("splash", or: "")
        verificationLevel = guildObject.get("verification_level", or: -1)
        voiceStates = DiscordVoiceState.voiceStatesFromArray(guildObject.get("voice_states", or: JSONArray()),
                                                             guildId: id)
        unavailable = guildObject.get("unavailable", or: false)
        joinedAt = DiscordDateFormatter.format(guildObject.get("joined_at", or: "")) ?? Date()
        self.client = client
        members = DiscordGuildMember.guildMembersFromArray(guildObject.get("members", or: JSONArray()),
                                                           withGuildId: id, guild: self)
    }

    // MARK: Methods

    ///
    /// Bans this user from the guild.
    ///
    /// - parameter member: The member to ban.
    /// - parameter deleteMessageDays: The number of days going back to delete messages. Defaults to 7.
    /// - parameter reason: The reason for this ban.
    ///
    public func ban(_ member: DiscordGuildMember, deleteMessageDays: Int = 7, reason: String? = nil) {
        guard let client = self.client else { return }

        client.guildBan(userId: member.user.id, on: id, deleteMessageDays: deleteMessageDays, reason: reason)
    }

    ///
    /// Creates a channel on this guild with `options`. The channel will not be immediately available; wait for a
    /// channel create event.
    ///
    /// - parameter with: The options for this new channel
    /// - parameter reason: The reason this channel is being created.
    ///
    public func createChannel(with options: [DiscordEndpoint.Options.GuildCreateChannel], reason: String? = nil) {
        guard let client = self.client else { return }

        logger.info("Creating guild channel on \(id)")

        client.createGuildChannel(on: id, options: options, reason: reason)
    }

    ///
    /// Gets the audit log for this guild.
    ///
    /// - parameter withOptions: The options to use when getting the logs.
    /// - parameter callback: The callback.
    ///
    public func getAuditLog(withOptions options: [DiscordEndpoint.Options.AuditLog] = [],
                            callback: @escaping (DiscordAuditLog?, HTTPURLResponse?) -> ()) {
        guard let client = self.client else { return callback(nil, nil) }

        client.getGuildAuditLog(for: id, withOptions: options, callback: {log, response in
            callback(log, response)
        })
    }

    ///
    /// Gets the bans for this guild.
    ///
    /// - parameter callback: The callback.
    ///
    public func getBans(callback: @escaping ([DiscordBan], HTTPURLResponse?) -> ()) {
        guard let client = self.client else { return callback([], nil) }

        client.getGuildBans(for: id) {bans, response in
            callback(bans, response)
        }
    }

    ///
    /// Gets a guild member by their user id.
    ///
    /// - parameter userId: The user id of the member to get
    ///
    public func getGuildMember(_ userId: UserID, callback: @escaping (DiscordGuildMember?, HTTPURLResponse?) -> ()) {
        guard let client = self.client else { return callback(nil, nil) }

        client.getGuildMember(by: userId, on: id) {member, response in
            logger.debug("Got member: \(userId)")

            var member = member
            member?.guild = self

            callback(member, response)
        }
    }

    // Used to setup initial guilds
    static func guildsFromArray(_ guilds: [[String: Any]], client: DiscordClient? = nil) -> [GuildID: DiscordGuild] {
        var guildDictionary = [GuildID: DiscordGuild]()

        for guildObject in guilds {
            let guild = DiscordGuild(guildObject: guildObject, client: client)

            guildDictionary[guild.id] = guild
        }

        return guildDictionary
    }

    ///
    /// Modifies this guild with `options`.
    ///
    /// - parameter options: An array of options to change.
    /// - parameter reason: The reason for this change.
    ///
    public func modifyGuild(options: [DiscordEndpoint.Options.ModifyGuild], reason: String? = nil) {
        guard let client = self.client else { return }

        client.modifyGuild(id, options: options, reason: reason)
    }

    ///
    /// Modifies a guild member.
    ///
    /// - parameter member: The member to modify.
    /// - parameter options: The options to set.
    ///
    public func modifyMember(_ member: DiscordGuildMember, options: [DiscordEndpoint.Options.ModifyMember]) {
        guard let client = self.client else { return }

        client.modifyGuildMember(member.user.id, on: id, options: options)
    }

    ///
    /// Gets the roles that this member has on this guild.
    ///
    /// - parameter member: The member whose roles we are getting.
    /// - returns: An array containing the roles they have.
    ///
    public func roles(for member: DiscordGuildMember) -> [DiscordRole] {
        var roles = [DiscordRole]()

        if let everyone = self.roles[id] {
            roles.append(everyone)
        }

        return roles + self.roles.filter({ member.roleIds.contains($0.key) }).map({ $0.1 })
    }

    func shardNumber(assuming numOfShards: Int) -> Int {
        return Int(id.rawValue >> 22) % numOfShards
    }

    func updateGuild(fromPresence presence: DiscordPresence,
                     fillingUsers fillUsers: Bool,
                     pruningUsers pruneUsers: Bool) {
        let userId = presence.user.id

        if pruneUsers && presence.status == .offline {
            logger.debug("Pruning guild member \(userId) on \(id)")

            members[userId] = nil
            presences[userId] = nil
        } else if fillUsers && !members.contains(userId) {
            logger.debug("Should get member \(userId); pull from the API")

            members[lazy: userId] = .lazy({[weak self] in
                guard let this = self else {
                    return DiscordGuildMember(guildMemberObject: [:], guildId: 0)
                }

                // Call out for the member
                this.getGuildMember(userId) {member, _ in
                    guard let member = member else { return }

                    self?.members[userId] = member
                }

                // Return a placeholder
                return DiscordGuildMember(guildMemberObject: ["user": ["id": String(describing: userId)]],
                                          guildId: this.id)
            })
        }
    }

    // Used to update a guild from a guildUpdate event
    func updateGuild(fromGuildUpdate newGuild: [String: Any]) -> DiscordGuild {
        if let defaultMessageNotifications = newGuild["default_message_notifications"] as? Int {
            self.defaultMessageNotifications = defaultMessageNotifications
        }

        if let widgetChannelId = Snowflake(newGuild["widget_channel_id"] as? String) {
            self.widgetChannelId = widgetChannelId
        }

        if let widgetEnabled = newGuild["widget_enabled"] as? Bool {
            self.widgetEnabled = widgetEnabled
        }

        if let icon = newGuild["icon"] as? String {
            self.icon = icon
        }

        if let banner = newGuild["banner"] as? String {
            self.banner = banner
        }

        if let memberCount = newGuild["member_count"] as? Int {
            self.memberCount = memberCount
        }

        if let mfaLevel = newGuild["mfa_level"] as? Int {
            self.mfaLevel = mfaLevel
        }

        if let name = newGuild["name"] as? String {
            self.name = name
        }

        if let ownerId = Snowflake(newGuild["owner_id"] as? String) {
            self.ownerId = ownerId
        }

        if let region = newGuild["region"] as? String {
            self.region = region
        }

        if let verificationLevel = newGuild["verification_level"] as? Int {
            self.verificationLevel = verificationLevel
        }

        return self
    }

    ///
    /// Unbans the specified user from the guild.
    ///
    /// - parameter user: The user to unban
    ///
    public func unban(_ user: DiscordUser) {
        guard let client = self.client else { return }

        logger.info("Unbanning user \(user) on \(id)")

        client.removeGuildBan(for: user.id, on: id)
    }
}
