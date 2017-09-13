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

/// Represents a Guild.
public final class DiscordGuild : DiscordClientHolder, CustomStringConvertible {
    private static let logType = "DiscordGuild"

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
    public private(set) var embedChannelId: ChannelID

    /// Whether this guild has embed enabled.
    public private(set) var embedEnabled: Bool

    /// The base64 encoded icon image for this guild.
    public private(set) var icon: String

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
        id = Snowflake(guildObject["id"] as? String) ?? 0
        channels = guildChannels(fromArray: guildObject.get("channels", or: JSONArray()), guildID: id, client: client)
        defaultMessageNotifications = guildObject.get("default_message_notifications", or: -1)
        embedEnabled = guildObject.get("embed_enabled", or: false)
        embedChannelId = Snowflake(guildObject["embed_channel_id"] as? String) ?? 0
        emojis = DiscordEmoji.emojisFromArray(guildObject.get("emojis", or: JSONArray()))
        features = guildObject.get("features", or: Array<Any>())
        icon = guildObject.get("icon", or: "")
        large = guildObject.get("large", or: false)
        memberCount = guildObject.get("member_count", or: 0)
        mfaLevel = guildObject.get("mfa_level", or: -1)
        name = guildObject.get("name", or: "")
        ownerId = Snowflake(guildObject["owner_id"] as? String) ?? 0

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

        DefaultDiscordLogger.Logger.log("Creating guild channel on \(id)", type: "DiscordGuild")

        client.createGuildChannel(on: id, options: options, reason: reason)
    }

    ///
    /// Gets the audit log for this guild.
    ///
    /// **NOTE** This is a blocking method. If you need an async version use the `getGuildAuditLog` method from
    /// `DiscordEndpointConsumer`, which is available on `DiscordClient`.
    ///
    /// - returns: A `DiscordAuditLog` for this guild.
    ///
    public func getAuditLog(withOptions options: [DiscordEndpoint.Options.AuditLog] = []) -> DiscordAuditLog? {
        guard let client = self.client else { return nil }

        let lock = DispatchSemaphore(value: 0)
        var auditLog: DiscordAuditLog?

        client.getGuildAuditLog(for: id, withOptions: options, callback: {log in
            auditLog = log

            lock.signal()
        })

        lock.wait()

        return auditLog
    }

    ///
    /// Gets the bans for this guild.
    ///
    /// **NOTE**: This is a blocking method. If you need an async version use the `getGuildBans` method from
    /// `DiscordEndpointConsumer`, which is available on `DiscordClient`.
    ///
    /// - returns: An array of `DiscordUser`s who are banned on this guild
    ///
    public func getBans() -> [DiscordBan] {
        guard let client = self.client else { return [] }

        let lock = DispatchSemaphore(value: 0)
        var bannedUsers: [DiscordBan]!

        client.getGuildBans(for: id) {bans in
            bannedUsers = bans

            lock.signal()
        }

        lock.wait()

        return bannedUsers
    }

    ///
    /// Gets a guild member by their user id.
    ///
    /// **NOTE**: This is a blocking method. If you need an async version user the `getGuildMember` method from
    /// `DiscordEndpointConsumer`, which is available on `DiscordClient`.
    ///
    /// - parameter userId: The user id of the member to get
    /// - returns: The guild member, if one was found
    ///
    public func getGuildMember(_ userId: UserID) -> DiscordGuildMember? {
        guard let client = self.client else { return nil }

        let lock = DispatchSemaphore(value: 0)
        var guildMember: DiscordGuildMember?

        client.getGuildMember(by: userId, on: id) {member in
            DefaultDiscordLogger.Logger.debug("Got member: \(userId)", type: "DiscordGuild")

            guildMember = member

            lock.signal()
        }

        lock.wait()

        return guildMember
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
            DefaultDiscordLogger.Logger.debug("Pruning guild member \(userId) on \(id)", type: DiscordGuild.logType)

            members[userId] = nil
            presences[userId] = nil
        } else if fillUsers && !members.contains(userId) {
            DefaultDiscordLogger.Logger.debug("Should get member \(userId); pull from the API", type: DiscordGuild.logType)

            members[lazy: userId] = .lazy({[weak self] in
                guard let this = self else {
                    return DiscordGuildMember(guildMemberObject: [:], guildId: 0)
                }

                return this.getGuildMember(userId) ?? DiscordGuildMember(guildMemberObject: [:], guildId: 0)
            })
        }
    }

    // Used to update a guild from a guildUpdate event
    func updateGuild(fromGuildUpdate newGuild: [String: Any]) -> DiscordGuild {
        if let defaultMessageNotifications = newGuild["default_message_notifications"] as? Int {
            self.defaultMessageNotifications = defaultMessageNotifications
        }

        if let embedChannelId = Snowflake(newGuild["embed_channel_id"] as? String) {
            self.embedChannelId = embedChannelId
        }

        if let embedEnabled = newGuild["embed_enabled"] as? Bool {
            self.embedEnabled = embedEnabled
        }

        if let icon = newGuild["icon"] as? String {
            self.icon = icon
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

        DefaultDiscordLogger.Logger.log("Unbanning user \(user) on \(id)", type: "DiscordGuild")

        client.removeGuildBan(for: user.id, on: id)
    }
}
