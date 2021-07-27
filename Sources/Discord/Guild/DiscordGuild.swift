// The MIT License (MIT)
// Copyright (c) 2016 Erik Little
// Copyright (c) 2021 fwcd

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
public final class DiscordGuild: CustomStringConvertible, Identifiable, Codable {
    public enum CodingKeys: String, CodingKey {
        case id
        case channels
        case defaultMessageNotifications = "default_message_notifications"
        case widgetEnabled = "widget_enabled"
        case widgetChannelId = "widget_channel_id"
        case emojis
        case features
        case icon
        case banner
        case large
        case memberCount = "member_count"
        case mfaLevel = "mfa_level"
        case name
        case ownerId = "owner_id"
        case presences
        case region
        case roles
        case splash
        case verificationLevel = "verification_level"
        case voiceStates = "voice_states"
        case unavailable
        case joinedAt = "joined_at"
        case members
    }

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

    /// A dictionary of this guild's channels. The key is the snowflake id of the channel.
    public internal(set) var channels: DiscordIDDictionary<DiscordGuildChannel>

    /// A dictionary of this guild's emojis. The key is the snowflake id of the emoji.
    public internal(set) var emojis: DiscordIDDictionary<DiscordEmoji>

    /// The number of members in this guild.
    ///
    /// *This number might not be the actual number of users in the `members` field.*
    public internal(set) var memberCount: Int

    /// A `DiscordLazyDictionary` of presences. The key is the snowflake id of the user.
    public internal(set) var presences = DiscordLazyDictionary<UserID, DiscordPresence>()

    /// A dictionary of this guild's roles. The key is the snowflake id of the role.
    public internal(set) var roles: DiscordIDDictionary<DiscordRole>

    /// A dictionary of this guild's current voice states. The key is the snowflake id of the user for this voice
    /// state.
    public internal(set) var voiceStates: DiscordIDDictionary<DiscordVoiceState>

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

    // MARK: Methods

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
