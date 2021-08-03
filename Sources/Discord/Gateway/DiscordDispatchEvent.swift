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

// A gateway event from Discord.
public enum DiscordDispatchEvent: Decodable {
    case ready(DiscordReadyEvent)
    case resumed

    // Messaging
    case messageCreate(DiscordMessageCreateEvent)
    case messageDelete(DiscordMessageDeleteEvent)
    case messageDeleteBulk(DiscordMessageDeleteBulkEvent)
    case messageReactionAdd(DiscordMessageReactionAddEvent)
    case messageReactionRemove(DiscordMessageReactionRemoveEvent)
    case messageReactionRemoveAll(DiscordMessageReactionRemoveAllEvent)
    case messageUpdate(DiscordMessageUpdateEvent)

    // Guilds
    case guildBanAdd(DiscordGuildBanAddEvent)
    case guildBanRemove(DiscordGuildBanRemoveEvent)
    case guildCreate(DiscordGuildCreateEvent)
    case guildDelete(DiscordGuildDeleteEvent)
    case guildEmojisUpdate(DiscordGuildEmojisUpdateEvent)
    case guildIntegrationsUpdate(DiscordGuildIntegrationsUpdateEvent)
    case guildMemberAdd(DiscordGuildMemberAddEvent)
    case guildMemberUpdate(DiscordGuildMemberUpdateEvent)
    case guildMemberRemove(DiscordGuildMemberRemoveEvent)
    case guildMembersChunk(DiscordGuildMembersChunkEvent)
    case guildRoleCreate(DiscordGuildRoleCreateEvent)
    case guildRoleUpdate(DiscordGuildRoleUpdateEvent)
    case guildRoleDelete(DiscordGuildRoleDeleteEvent)
    case guildUpdate(DiscordGuildUpdateEvent)
    case presenceUpdate(DiscordPresenceUpdateEvent)

    // Channels
    case channelCreate(DiscordChannelCreateEvent)
    case channelDelete(DiscordChannelDeleteEvent)
    case channelPinsUpdate(DiscordChannelPinsUpdateEvent)
    case channelUpdate(DiscordChannelUpdateEvent)

    // Threads
    case threadCreate(DiscordThreadCreateEvent)
    case threadUpdate(DiscordThreadUpdateEvent)
    case threadDelete(DiscordThreadDeleteEvent)
    case threadListSync(DiscordThreadListSyncEvent)
    case threadMemberUpdate(DiscordThreadMemberUpdateEvent)
    case threadMembersUpdate(DiscordThreadMembersUpdateEvent)

    // Voice
    case voiceServerUpdate(DiscordVoiceServerUpdateEvent)
    case voiceStateUpdate(DiscordVoiceStateUpdateEvent)
    case typingStart(DiscordTypingStartEvent)

    // Users
    case userUpdate(DiscordUserUpdateEvent)

    // Webhooks
    case webhooksUpdate(DiscordWebhooksUpdateEvent)

    // Applications
    case applicationCommandCreate(DiscordApplicationCommandCreateEvent)
    case applicationCommandUpdate(DiscordApplicationCommandUpdateEvent)

    // Interactions
    case interactionCreate(DiscordInteractionCreateEvent)

    public enum CodingKeys: String, CodingKey {
        case type = "t"
        case data = "d"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(DiscordDispatchEventType.self, forKey: .type)

        switch type {
        case .ready: self = .ready(try container.decode(DiscordReadyEvent.self, forKey: .data))
        case .resumed: self = .resumed
        case .messageCreate: self = .messageCreate(try container.decode(DiscordMessageCreateEvent.self, forKey: .data))
        case .messageDelete: self = .messageDelete(try container.decode(DiscordMessageDeleteEvent.self, forKey: .data))
        case .messageDeleteBulk: self = .messageDeleteBulk(try container.decode(DiscordMessageDeleteBulkEvent.self, forKey: .data))
        case .messageReactionAdd: self = .messageReactionAdd(try container.decode(DiscordMessageReactionAddEvent.self, forKey: .data))
        case .messageReactionRemove: self = .messageReactionRemove(try container.decode(DiscordMessageReactionRemoveEvent.self, forKey: .data))
        case .messageReactionRemoveAll: self = .messageReactionRemoveAll(try container.decode(DiscordMessageReactionRemoveAllEvent.self, forKey: .data))
        case .messageUpdate: self = .messageUpdate(try container.decode(DiscordMessageUpdateEvent.self, forKey: .data))
        case .guildBanAdd: self = .guildBanAdd(try container.decode(DiscordGuildBanAddEvent.self, forKey: .data))
        case .guildBanRemove: self = .guildBanRemove(try container.decode(DiscordGuildBanRemoveEvent.self, forKey: .data))
        case .guildCreate: self = .guildCreate(try container.decode(DiscordGuildCreateEvent.self, forKey: .data))
        case .guildDelete: self = .guildDelete(try container.decode(DiscordGuildDeleteEvent.self, forKey: .data))
        case .guildEmojisUpdate: self = .guildEmojisUpdate(try container.decode(DiscordGuildEmojisUpdateEvent.self, forKey: .data))
        case .guildIntegrationsUpdate: self = .guildIntegrationsUpdate(try container.decode(DiscordGuildIntegrationsUpdateEvent.self, forKey: .data))
        case .guildMemberAdd: self = .guildMemberAdd(try container.decode(DiscordGuildMemberAddEvent.self, forKey: .data))
        case .guildMemberUpdate: self = .guildMemberUpdate(try container.decode(DiscordGuildMemberUpdateEvent.self, forKey: .data))
        case .guildMemberRemove: self = .guildMemberRemove(try container.decode(DiscordGuildMemberRemoveEvent.self, forKey: .data))
        case .guildMembersChunk: self = .guildMembersChunk(try container.decode(DiscordGuildMembersChunkEvent.self, forKey: .data))
        case .guildRoleCreate: self = .guildRoleCreate(try container.decode(DiscordGuildRoleCreateEvent.self, forKey: .data))
        case .guildRoleUpdate: self = .guildRoleUpdate(try container.decode(DiscordGuildRoleUpdateEvent.self, forKey: .data))
        case .guildRoleDelete: self = .guildRoleDelete(try container.decode(DiscordGuildRoleDeleteEvent.self, forKey: .data))
        case .guildUpdate: self = .guildUpdate(try container.decode(DiscordGuildUpdateEvent.self, forKey: .data))
        case .presenceUpdate: self = .presenceUpdate(try container.decode(DiscordPresenceUpdateEvent.self, forKey: .data))
        case .channelCreate: self = .channelCreate(try container.decode(DiscordChannelCreateEvent.self, forKey: .data))
        case .channelDelete: self = .channelDelete(try container.decode(DiscordChannelDeleteEvent.self, forKey: .data))
        case .channelPinsUpdate: self = .channelPinsUpdate(try container.decode(DiscordChannelPinsUpdateEvent.self, forKey: .data))
        case .channelUpdate: self = .channelUpdate(try container.decode(DiscordChannelUpdateEvent.self, forKey: .data))
        case .threadCreate: self = .threadCreate(try container.decode(DiscordThreadCreateEvent.self, forKey: .data))
        case .threadUpdate: self = .threadUpdate(try container.decode(DiscordThreadUpdateEvent.self, forKey: .data))
        case .threadDelete: self = .threadDelete(try container.decode(DiscordThreadDeleteEvent.self, forKey: .data))
        case .threadListSync: self = .threadListSync(try container.decode(DiscordThreadListSyncEvent.self, forKey: .data))
        case .threadMemberUpdate: self = .threadMemberUpdate(try container.decode(DiscordThreadMemberUpdateEvent.self, forKey: .data))
        case .threadMembersUpdate: self = .threadMembersUpdate(try container.decode(DiscordThreadMembersUpdateEvent.self, forKey: .data))
        case .voiceServerUpdate: self = .voiceServerUpdate(try container.decode(DiscordVoiceServerUpdateEvent.self, forKey: .data))
        case .voiceStateUpdate: self = .voiceStateUpdate(try container.decode(DiscordVoiceStateUpdateEvent.self, forKey: .data))
        case .typingStart: self = .typingStart(try container.decode(DiscordTypingStartEvent.self, forKey: .data))
        case .userUpdate: self = .userUpdate(try container.decode(DiscordUserUpdateEvent.self, forKey: .data))
        case .webhooksUpdate: self = .webhooksUpdate(try container.decode(DiscordWebhooksUpdateEvent.self, forKey: .data))
        case .applicationCommandCreate: self = .applicationCommandCreate(try container.decode(DiscordApplicationCommandCreateEvent.self, forKey: .data))
        case .applicationCommandUpdate: self = .applicationCommandUpdate(try container.decode(DiscordApplicationCommandUpdateEvent.self, forKey: .data))
        case .interactionCreate: self = .interactionCreate(try container.decode(DiscordInteractionCreateEvent.self, forKey: .data))
        default: throw DiscordDispatchEventError.unknownEventType(type)
        }
    }
}

public enum DiscordDispatchEventError: Error {
    case unknownEventType(DiscordDispatchEventType)
}

/// An enum that represents the dispatch events Discord sends.
public struct DiscordDispatchEventType: RawRepresentable, Codable, Hashable {
    public let rawValue: String

    public static let ready = DiscordDispatchEventType(rawValue: "READY")
    public static let resumed = DiscordDispatchEventType(rawValue: "RESUMED")

    // Messaging

    public static let messageCreate = DiscordDispatchEventType(rawValue: "MESSAGE_CREATE")
    public static let messageDelete = DiscordDispatchEventType(rawValue: "MESSAGE_DELETE")
    public static let messageDeleteBulk = DiscordDispatchEventType(rawValue: "MESSAGE_DELETE_BULK")
    public static let messageReactionAdd = DiscordDispatchEventType(rawValue: "MESSAGE_REACTION_ADD")
    public static let messageReactionRemoveAll = DiscordDispatchEventType(rawValue: "MESSAGE_REACTION_REMOVE_ALL")
    public static let messageReactionRemove = DiscordDispatchEventType(rawValue: "MESSAGE_REACTION_REMOVE")
    public static let messageUpdate = DiscordDispatchEventType(rawValue: "MESSAGE_UPDATE")

    // Guilds

    public static let guildBanAdd = DiscordDispatchEventType(rawValue: "GUILD_BAN_ADD")
    public static let guildBanRemove = DiscordDispatchEventType(rawValue: "GUILD_BAN_REMOVE")
    public static let guildCreate = DiscordDispatchEventType(rawValue: "GUILD_CREATE")
    public static let guildDelete = DiscordDispatchEventType(rawValue: "GUILD_DELETE")
    public static let guildEmojisUpdate = DiscordDispatchEventType(rawValue: "GUILD_EMOJIS_UPDATE")
    public static let guildIntegrationsUpdate = DiscordDispatchEventType(rawValue: "GUILD_INTEGRATIONS_UPDATE")
    public static let guildMemberAdd = DiscordDispatchEventType(rawValue: "GUILD_MEMBER_ADD")
    public static let guildMemberRemove = DiscordDispatchEventType(rawValue: "GUILD_MEMBER_REMOVE")
    public static let guildMemberUpdate = DiscordDispatchEventType(rawValue: "GUILD_MEMBER_UPDATE")
    public static let guildMembersChunk = DiscordDispatchEventType(rawValue: "GUILD_MEMBERS_CHUNK")
    public static let guildRoleCreate = DiscordDispatchEventType(rawValue: "GUILD_ROLE_CREATE")
    public static let guildRoleDelete = DiscordDispatchEventType(rawValue: "GUILD_ROLE_DELETE")
    public static let guildRoleUpdate = DiscordDispatchEventType(rawValue: "GUILD_ROLE_UPDATE")
    public static let guildUpdate = DiscordDispatchEventType(rawValue: "GUILD_UPDATE")

    // Channels

    public static let channelCreate = DiscordDispatchEventType(rawValue: "CHANNEL_CREATE")
    public static let channelDelete = DiscordDispatchEventType(rawValue: "CHANNEL_DELETE")
    public static let channelPinsUpdate = DiscordDispatchEventType(rawValue: "CHANNEL_PINS_UPDATE")
    public static let channelUpdate = DiscordDispatchEventType(rawValue: "CHANNEL_UPDATE")

    // Threads

    public static let threadCreate = DiscordDispatchEventType(rawValue: "THREAD_CREATE")
    public static let threadUpdate = DiscordDispatchEventType(rawValue: "THREAD_UPDATE")
    public static let threadDelete = DiscordDispatchEventType(rawValue: "THREAD_DELETE")
    public static let threadListSync = DiscordDispatchEventType(rawValue: "THREAD_LIST_SYNC")
    public static let threadMemberUpdate = DiscordDispatchEventType(rawValue: "THREAD_MEMBER_UPDATE")
    public static let threadMembersUpdate = DiscordDispatchEventType(rawValue: "THREAD_MEMBERS_UPDATE")

    // Voice

    public static let voiceServerUpdate = DiscordDispatchEventType(rawValue: "VOICE_SERVER_UPDATE")
    public static let voiceStateUpdate = DiscordDispatchEventType(rawValue: "VOICE_STATE_UPDATE")
    public static let presenceUpdate = DiscordDispatchEventType(rawValue: "PRESENCE_UPDATE")
    public static let typingStart = DiscordDispatchEventType(rawValue: "TYPING_START")

    // Webhooks

    public static let webhooksUpdate = DiscordDispatchEventType(rawValue: "WEBHOOKS_UPDATE")

    // Applications

    public static let applicationCommandCreate = DiscordDispatchEventType(rawValue: "APPLICATION_COMMAND_CREATE")
    public static let applicationCommandUpdate = DiscordDispatchEventType(rawValue: "APPLICATION_COMMAND_UPDATE")

    // Users
    
    public static let userUpdate = DiscordDispatchEventType(rawValue: "USER_UPDATE")

    // Interactions

    public static let interactionCreate = DiscordDispatchEventType(rawValue: "INTERACTION_CREATE")

    public init(rawValue: String) {
        self.rawValue = rawValue
    }
}

public typealias DiscordMessageCreateEvent = DiscordMessage
public typealias DiscordMessageUpdateEvent = DiscordMessage
public typealias DiscordMessageReactionAddEvent = DiscordMessageReactionUpdateEvent
public typealias DiscordMessageReactionRemoveEvent = DiscordMessageReactionUpdateEvent
public typealias DiscordGuildCreateEvent = DiscordGuild
public typealias DiscordGuildUpdateEvent = DiscordGuild
public typealias DiscordGuildDeleteEvent = DiscordGuild
public typealias DiscordGuildMemberAddEvent = DiscordGuildMember
public typealias DiscordGuildMemberUpdateEvent = DiscordGuildMember
public typealias DiscordGuildRoleCreateEvent = DiscordGuildRoleUpdateEvent
public typealias DiscordPresenceUpdateEvent = DiscordPresence
public typealias DiscordChannelCreateEvent = DiscordChannel
public typealias DiscordChannelUpdateEvent = DiscordChannel
public typealias DiscordChannelDeleteEvent = DiscordChannel
public typealias DiscordThreadCreateEvent = DiscordChannel
public typealias DiscordThreadUpdateEvent = DiscordChannel
public typealias DiscordThreadDeleteEvent = DiscordChannel
public typealias DiscordThreadMemberUpdateEvent = DiscordThreadMember
public typealias DiscordVoiceStateUpdateEvent = DiscordVoiceState
public typealias DiscordApplicationCommandCreateEvent = DiscordApplicationCommand
public typealias DiscordApplicationCommandUpdateEvent = DiscordApplicationCommand
public typealias DiscordApplicationCommandDeleteEvent = DiscordApplicationCommand
public typealias DiscordInteractionCreateEvent = DiscordInteraction
public typealias DiscordUserUpdateEvent = DiscordUser

public struct DiscordReadyEvent: Codable {
    public enum CodingKeys: String, CodingKey {
        case gatewayVersion = "v"
        case user
        case guilds
        case sessionId = "session_id"
        case shard
        case application
    }

    /// The gateway version.
    public var gatewayVersion: Int?

    /// Information about the user including email.
    public var user: DiscordUser?

    /// The guilds the user is in.
    /// Note that the guilds are unavailable and thus only have their
    /// `id` and `unavailable` fields specified.
    public var guilds: [DiscordGuild]? = nil

    /// Used for resuming connections.
    public var sessionId: String? = nil

    /// The shard information associated with this session, if sent
    /// when identifying. An array of two integers:
    /// - shard_id
    /// - num_shards
    public var shard: [Int]? = nil

    /// The partial application object (contains `id` and `flags`).
    public var application: DiscordApplication? = nil
}

/// Sent when a guild's voixce server is updated.
public struct DiscordVoiceServerUpdateEvent: Codable {
    public enum CodingKeys: String, CodingKey {
        case token
        case guildId = "guild_id"
        case endpoint
    }

    /// The voice connection token.
    public var token: String

    /// The guild this voice server update is for.
    public var guildId: GuildID?

    /// The voice server host.
    public var endpoint: String?
}

/// Sent when the current user *gains* access to a channel
public struct DiscordThreadListSyncEvent: Codable {
    public enum CodingKeys: String, CodingKey {
        case guildId = "guild_id"
        case channelIds = "channel_ids"
        case threads
        case members
    }

    /// The id of the guild.
    public var guildId: GuildID?
    /// The parent channel ids whose threads are being synced. If omitted, then
    /// threads were synced for the entire guild. This array may contain channel_ids
    /// that have no active threads as well, so you know to clear that data.
    public var channelIds: [ChannelID]?
    /// All active threads in the given channels that the current user can access.
    public var threads: [DiscordChannel]
    /// All thread member objects from the synced threads for the current user,
    /// indicating which threads the current user has been added to.
    public var members: [DiscordThreadMember]
}

/// Sent when a user is banned from a guild.
public struct DiscordGuildBanAddEvent: Codable {
    public enum CodingKeys: String, CodingKey {
        case guildId = "guild_id"
        case user
    }

    /// The id of the guild.
    public var guildId: GuildID
    /// The banned user.
    public var user: DiscordUser
}

/// Sent when a user is unbanned from a guild.
public struct DiscordGuildBanRemoveEvent: Codable {
    public enum CodingKeys: String, CodingKey {
        case guildId = "guild_id"
        case user
    }

    /// The id of the guild.
    public var guildId: GuildID
    /// The banned user.
    public var user: DiscordUser
}

/// Sent when a guild's emojis have been updated.
public struct DiscordGuildEmojisUpdateEvent: Codable {
    public enum CodingKeys: String, CodingKey {
        case guildId = "guild_id"
        case emojis
    }

    /// The id of the guild.
    public var guildId: GuildID
    /// The emojis updated.
    public var emojis: [DiscordEmoji]
}

/// Sent when a guild's stickers have been updated.
public struct DiscordGuildSticksUpdateEvent: Codable {
    public enum CodingKeys: String, CodingKey {
        case guildId = "guild_id"
        case stickers
    }

    /// The id of the guild.
    public var guildId: GuildID
    /// The stickers updated.
    public var stickers: [DiscordSticker]
}

/// Sent when a guild's integration is updated.
public struct DiscordGuildIntegrationsUpdateEvent: Codable {
    public enum CodingKeys: String, CodingKey {
        case guildId = "guild_id"
    }

    /// The id of the guild.
    public var guildId: GuildID
}

/// Sent when a user is removed from a guild (leave/kick/ban):
public struct DiscordGuildMemberRemoveEvent: Codable {
    public enum CodingKeys: String, CodingKey {
        case guildId = "guild_id"
        case user
    }

    /// The id of the guild.
    public var guildId: GuildID
    /// The user who was removed.
    public var user: DiscordUser
}

/// Sent when a role is created/updated on a guild.
public struct DiscordGuildRoleUpdateEvent: Codable {
    public enum CodingKeys: String, CodingKey {
        case guildId = "guild_id"
        case role
    }

    /// The id of the guild.
    public var guildId: GuildID
    /// The role.
    public var role: DiscordRole
}

/// Sent when a role is removed from a guild.
public struct DiscordGuildRoleDeleteEvent: Codable {
    public enum CodingKeys: String, CodingKey {
        case guildId = "guild_id"
        case roleId = "role_id"
    }

    /// The id of the guild.
    public var guildId: GuildID
    /// The id of the role.
    public var roleId: RoleID
}

/// Sent in response to Guild Request Members. You can use `chunk_index` and `chunk_count`
/// to calculate how many chunks are left for your request.
public struct DiscordGuildMembersChunkEvent: Codable {
    public enum CodingKeys: String, CodingKey {
        case guildId = "guild_id"
        case members
        case chunkIndex = "chunk_index"
        case chunkCount = "chunk_count"
        case notFound = "not_found"
        case presences
        case nonce
    }

    /// The id of the guild.
    public var guildId: GuildID?
    /// Set of guild members.
    public var members: [DiscordGuildMember]
    /// The chunk index in the expected chunks for this response
    /// (0 <= chunkIndex < chunkCount).
    public var chunkIndex: Int
    /// The total number of expected chunks for this response.
    public var chunkCount: Int
    /// When passing an invalid id to the Guild Members Request, it will
    /// be returned here.
    public var notFound: [Snowflake]?
    /// When passing true to the Guild Members Request, presences of the
    /// returned members.
    public var presences: [DiscordPresence]?
    /// The nonce used in the Guild Members Request.
    public var nonce: String?
}

/// Sent when a message is pinned/unpinned in a text channel. Not sent if the
/// pinned message is deleted.
public struct DiscordChannelPinsUpdateEvent: Codable {
    public enum CodingKeys: String, CodingKey {
        case guildId = "guild_id"
        case channelId = "channel_id"
        case lastPinTimestamp = "last_pin_timestamp"
    }

    public var guildId: GuildID?
    public var channelId: ChannelID
    public var lastPinTimestamp: Date?
}

/// Sent when a message is deleted.
public struct DiscordMessageDeleteEvent: Codable {
    public enum CodingKeys: String, CodingKey {
        case id
        case channelId = "channel_id"
        case guildId = "guild_id"
    }

    /// The id of the message.
    public var id: MessageID
    /// The id of the channel.
    public var channelId: ChannelID
    /// The id of the guild.
    public var guildId: GuildID?
}

/// Sent when multiple messages are deleted at once.
public struct DiscordMessageDeleteBulkEvent: Codable {
    public enum CodingKeys: String, CodingKey {
        case ids
        case channelId = "channel_id"
        case guildId = "guild_id"
    }

    /// The ids of the messages.
    public var ids: [MessageID]
    /// The id of the channel.
    public var channelId: ChannelID
    /// The id of the guild.
    public var guildId: GuildID?
}

/// Sent when a single reaction is added/removed.
public struct DiscordMessageReactionUpdateEvent: Codable {
    public enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case channelId = "channel_id"
        case messageId = "message_id"
        case guildId = "guild_id"
        case emoji
        case member
    }

    /// The id of the user.
    public var userId: UserID
    /// The id of the channel.
    public var channelId: ChannelID
    /// The id of the message.
    public var messageId: MessageID
    /// The id of the guild.
    public var guildId: GuildID?
    /// The member who reacted if in a guild.
    /// Only specified on reaction additions.
    public var member: DiscordGuildMember?
    /// The emoji used to react.
    public var emoji: DiscordEmoji
}

/// Sent when a user explicitly removes all reactions from a message.
public struct DiscordMessageReactionRemoveAllEvent: Codable {
    public enum CodingKeys: String, CodingKey {
        case channelId = "channel_id"
        case messageId = "message_id"
        case guildId = "guild_id"
    }

    /// The id of the channel.
    public var channelId: ChannelID
    /// The id of the message.
    public var messageId: MessageID
    /// The id of the guild.
    public var guildId: GuildID?
}

/// Sent when a user explicitly removes all reactions of a given emoji from a message.
public struct DiscordMessageReactionRemoveEmojiEvent: Codable {
    public enum CodingKeys: String, CodingKey {
        case channelId = "channel_id"
        case messageId = "message_id"
        case guildId = "guild_id"
        case emoji
    }

    /// The id of the channel.
    public var channelId: ChannelID
    /// The id of the message.
    public var messageId: MessageID
    /// The id of the guild.
    public var guildId: GuildID?
    /// The removed emoji.
    public var emoji: DiscordEmoji
}

/// Sent when anyone is added/removed from a thread.
public struct DiscordThreadMembersUpdateEvent: Codable {
    public enum CodingKeys: String, CodingKey {
        case id
        case guildId = "guild_id"
        case memberCount = "member_count"
        case addedMembers = "added_members"
        case removedMemberIds = "removed_member_ids"
    }

    /// The id of the thread.
    public var id: ChannelID
    /// The id of the guild.
    public var guildId: GuildID
    /// The approximate number of members in the thread, capped at 50.
    public var memberCount: Int
    /// The users added to the thread.
    public var addedMembers: [DiscordThreadMember]?
    /// The ids of the users removed from the thread.
    public var removedMemberIds: [UserID]?
}

/// Sent when a user starts typing in a channel.
public struct DiscordTypingStartEvent: Codable {
    public enum CodingKeys: String, CodingKey {
        case channelId = "channel_id"
        case guildId = "guild_id"
        case userId = "user_id"
        case timestamp
        case member
    }

    /// The id of the channel.
    public var channelId: ChannelID
    /// The id of the guild.
    public var guildId: GuildID?
    /// The id of the user.
    public var userId: UserID
    /// The unix time in seconds of when the user started typing.
    public var timestamp: Int
    /// The member who started typing if this happened in a guild.
    public var member: DiscordGuildMember?
}

/// Sent when a guild channel's webhook is created, updated or deleted.
public struct DiscordWebhooksUpdateEvent: Codable {
    public enum CodingKeys: String, CodingKey {
        case guildId = "guild_id"
        case channelId = "channel_id"
    }

    /// The id of the guild.
    public var guildId: GuildID?
    /// The id of the channel.
    public var channelId: ChannelID
}
