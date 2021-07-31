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

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import Logging

import class Dispatch.DispatchSemaphore

fileprivate let logger = Logger(label: "DiscordChannel")

/// A Discord channel of unspecified type.
public struct DiscordChannel: Codable, Identifiable, Hashable {
    public enum CodingKeys: String, CodingKey {
        case id
        case type
        case guildId = "guild_id"
        case position
        case permissionOverwrites = "permission_overwrites"
        case name
        case topic
        case nsfw
        case lastMessageId = "last_message_id"
        case bitrate
        case userLimit = "user_limit"
        case rateLimitPerUser = "rate_limit_per_user"
        case recipients
        case icon
        case ownerId = "owner_id"
        case applicationId = "application_id"
        case parentId = "parent_id"
        case lastPinTimestamp = "last_pin_timestamp"
        case rtcRegion = "rtc_region"
        case videoQualityMode = "video_quality_mode"
        case messageCount = "message_count"
        case threadMetadata = "thread_metadata"
        case member
        case defaultAutoArchiveDuration = "default_auto_archive_duration"
        case permissions
    }

    /// The snowflake id of the channel.
    public var id: ChannelID

    /// The type of the channel.
    public var type: DiscordChannelType

    /// The id of the guild (may be missing for channel objects
    /// received via gateway guild dispatches).
    public var guildId: GuildID?

    /// The sorting position of the channel.
    public var position: Int?

    /// Explicit permission overwrites for members and roles.
    public var permissionOverwrites: DiscordIDDictionary<DiscordPermissionOverwrite>?

    /// The name of the channel.
    public var name: String?

    /// The channel topic.
    public var topic: String?

    /// Whether the channel is NSFW.
    public var nsfw: Bool?

    /// The id of the last message sent in this channel (may not point to an
    /// existing or valid message.)
    public var lastMessageId: MessageID?

    /// The bitrate in bits if this is a voice channel.
    public var bitrate: Int?

    /// The user limit if this is a voice channel.
    public var userLimit: Int?

    /// Amount of seconds a user has to wait before sending another message
    /// (0-21600): bots, as well as users with the permission
    /// `manage_messages` or `manage_channel` are unaffected
    public var rateLimitPerUser: Int?

    /// The recipients if this is a DM channel.
    public var recipients: [DiscordUser]?

    /// The icon hash.
    public var icon: String?

    /// The id of the creator of the group DM or thread.
    public var ownerId: UserID?

    /// The application id of the group DM creator if bot-created.
    public var applicationId: UserID?

    /// For guild channels the parent category, for threads the
    /// text channel in which the thread was created.
    public var parentId: ChannelID?

    /// When the last pinned message was pinned.
    public var lastPinTimestamp: Date?

    /// Voice region id for voice channels, automatic when set to null.
    public var rtcRegion: String?

    /// Camera video quality mode for the voice channel, 1 when not present.
    public var videoQualityMode: Int?

    /// The approximate message count in a thread, stops at 50.
    public var messageCount: Int?

    /// The approximate user count in a thread, stops at 50.
    public var memberCount: Int?

    /// Thread-specific metadata in a thread.
    public var threadMetadata: DiscordThreadMetadata?

    /// Thread member object for the current user if they have joined the
    /// thread, only included on certain API endpoints.
    public var member: DiscordThreadMember?

    /// Default duration for newly created threads, in minutes, to
    /// automatically archive the thread after recent activity, can be
    /// set to 60, 1440, 4320, 10080
    public var defaultAutoArchiveDuration: Int?

    /// Computed permissions for the invoking user in the channel.
    /// Only included when part of the resolved data received on
    /// a slash command interaction.
    public var permissions: DiscordPermissions?

    /// Whether this is a direct message.
    public var isDM: Bool { [.dm, .groupDM].contains(type) }
}

/// Represents the type of a channel.
public struct DiscordChannelType: RawRepresentable, Codable, Hashable {
    public var rawValue: Int

    /// A guild text channel.
    public static let text = DiscordChannelType(rawValue: 0)
    /// A direct message channel.
    public static let dm = DiscordChannelType(rawValue: 1)
    /// A voice channel within a guild.
    public static let voice = DiscordChannelType(rawValue: 2)
    /// A group direct message.
    public static let groupDM = DiscordChannelType(rawValue: 3)
    /// An organizational category in a guild that contains up to 50 channels.
    public static let category = DiscordChannelType(rawValue: 4)
    /// A channel that users can follow in their own guild.
    public static let news = DiscordChannelType(rawValue: 5)
    /// A channel in which game devs can sell their games on Discord.
    public static let store = DiscordChannelType(rawValue: 6)
    /// A temporary sub-channel in a guild news channel.
    public static let newsThread = DiscordChannelType(rawValue: 10)
    /// A temporary sub-channel within a guild text channel.
    public static let publicThread = DiscordChannelType(rawValue: 11)
    /// A temporary sub-channel in a guild text channel that is only viewable
    /// by those invited and those with the 'manage threads' permission.
    public static let privateThread = DiscordChannelType(rawValue: 12)
    /// A guild voice channel for hosting events with an audience.
    public static let stageVoice = DiscordChannelType(rawValue: 13)

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
}
