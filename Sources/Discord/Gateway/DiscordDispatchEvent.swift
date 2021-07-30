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

// A gateway event from Discord.
public enum DiscordDispatchEvent: Decodable {
    case ready(DiscordReadyEvent)
    case resumed(DiscordResumedEvent)

    // Messaging
    case messageCreate(DiscordMessageCreateEvent)
    case messageDelete(DiscordMessageDeleteEvent)
    case messageDeleteBulk(DiscordMessageDeleteBulkEvent)
    case messageReactionAdd(DiscordMessageReactionAddEvent)
    case messageReactionRemove(DiscordMessageReactionRemoveEvent)
    case messageReactionRemoveAll(DiscordMessageReactionRemoveAllEvent)
    case messageUpdate(DiscordMessageUpdate)

    // Guilds
    case guildBanAdd(DiscordGuildBanAddEvent)
    case guildBanRemove(DiscordGuildBanRemoveEvent)
    case guildCreate(DiscordGuildCreateEvent)
    case guildEmojisUpdate(DiscordGuildEmojisUpdateEvent)
    case guildIntegrationsUpdate(DiscordGuildIntegrationsUpdateEvent)
    case guildMemberAdd(DiscordGuildMemberAddEvent)
    case guildMemberRemove(DiscordGuildMemberRemoveEvent)
    case guildMembersChunk(DiscordGuildMembersChunkEvent)
    case guildRoleCreate(DiscordGuildRoleCreateEvent)
    case guildRoleDelete(DiscordGuildRoleDeleteEvent)
    case guildUpdate(DiscordGuildUpdateEvent)

    // Channels
    case channelCreate(DiscordChannelCreateEvent)
    case channelDelete(DiscordChannelDeleteEvent)
    case channelPinsUpdate(DiscordChannelPinsUpdateEvent)
    case channelUpdate(DiscordChannelUpdateEvent)

    // Threads
    case threadCreate(DiscordThreadCreateEvent)
    case threadUpdate(DiscordThreadUpdateEvent)
    case threadDelete(DiscordThreadDeleteEvent)
    case threadMemberUpdate(DiscordThreadMemberUpdateEvent)
    case threadMembersUpdate(DiscordThreadMembersUpdateEvent)

    // Voice
    case voiceServerUpdate(DiscordVoiceServerUpdateEvent)
    case voiceStateUpdate(DiscordVoiceStateUpdateEvent)
    case presenceUpdate(DiscordPresenceUpdateEvent)
    case typingStart(DiscordTypingStartEvent)

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
        case .resumed: self = .resumed(try container.decode(DiscordResumedEvent.self, forKey: .data))
        case .messageCreate: self = .messageCreate(try container.decode(DiscordMessageCreateEvent.self, forKey: .data))
        case .messageDelete: self = .messageDelete(try container.decode(DiscordMessageDeleteEvent.self, forKey: .data))
        case .messageDeleteBulk: self = .messageDeleteBulk(try container.decode(DiscordMessageDeleteBulkEvent.self, forKey: .data))
        case .messageReactionAdd: self = .messageReactionAdd(try container.decode(DiscordMessageReactionAddEvent.self, forKey: .data))
        case .messageReactionRemove: self = .messageReactionRemove(try container.decode(DiscordMessageReactionRemoveEvent.self, forKey: .data))
        case .messageReactionRemoveAll: self = .messageReactionRemoveAll(try container.decode(DiscordMessageReactionRemoveAllEvent.self, forKey: .data))
        case .messageUpdate: self = .messageUpdate(try container.decode(DiscordMessageUpdate.self, forKey: .data))
        case .guildBanAdd: self = .guildBanAdd(try container.decode(DiscordGuildBanAddEvent.self, forKey: .data))
        case .guildBanRemove: self = .guildBanRemove(try container.decode(DiscordGuildBanRemoveEvent.self, forKey: .data))
        case .guildCreate: self = .guildCreate(try container.decode(DiscordGuildCreateEvent.self, forKey: .data))
        case .guildEmojisUpdate: self = .guildEmojisUpdate(try container.decode(DiscordGuildEmojisUpdateEvent.self, forKey: .data))
        case .guildIntegrationsUpdate: self = .guildIntegrationsUpdate(try container.decode(DiscordGuildIntegrationsUpdateEvent.self, forKey: .data))
        case .guildMemberAdd: self = .guildMemberAdd(try container.decode(DiscordGuildMemberAddEvent.self, forKey: .data))
        case .guildMemberRemove: self = .guildMemberRemove(try container.decode(DiscordGuildMemberRemoveEvent.self, forKey: .data))
        case .guildMembersChunk: self = .guildMembersChunk(try container.decode(DiscordGuildMembersChunkEvent.self, forKey: .data))
        case .guildRoleCreate: self = .guildRoleCreate(try container.decode(DiscordGuildRoleCreateEvent.self, forKey: .data))
        case .guildRoleDelete: self = .guildRoleDelete(try container.decode(DiscordGuildRoleDeleteEvent.self, forKey: .data))
        case .guildUpdate: self = .guildUpdate(try container.decode(DiscordGuildUpdateEvent.self, forKey: .data))
        case .channelCreate: self = .channelCreate(try container.decode(DiscordChannelCreateEvent.self, forKey: .data))
        case .channelDelete: self = .channelDelete(try container.decode(DiscordChannelDeleteEvent.self, forKey: .data))
        case .channelPinsUpdate: self = .channelPinsUpdate(try container.decode(DiscordChannelPinsUpdateEvent.self, forKey: .data))
        case .channelUpdate: self = .channelUpdate(try container.decode(DiscordChannelUpdateEvent.self, forKey: .data))
        case .threadCreate: self = .threadCreate(try container.decode(DiscordThreadCreateEvent.self, forKey: .data))
        case .threadUpdate: self = .threadUpdate(try container.decode(DiscordThreadUpdateEvent.self, forKey: .data))
        case .threadDelete: self = .threadDelete(try container.decode(DiscordThreadDeleteEvent.self, forKey: .data))
        case .threadMemberUpdate: self = .threadMemberUpdate(try container.decode(DiscordThreadMemberUpdateEvent.self, forKey: .data))
        case .threadMembersUpdate: self = .threadMembersUpdate(try container.decode(DiscordThreadMembersUpdateEvent.self, forKey: .data))
        case .voiceServerUpdate: self = .voiceServerUpdate(try container.decode(DiscordVoiceServerUpdateEvent.self, forKey: .data))
        case .voiceStateUpdate: self = .voiceStateUpdate(try container.decode(DiscordVoiceStateUpdateEvent.self, forKey: .data))
        case .presenceUpdate: self = .presenceUpdate(try container.decode(DiscordPresenceUpdateEvent.self, forKey: .data))
        case .typingStart: self = .typingStart(try container.decode(DiscordTypingStartEvent.self, forKey: .data))
        case .webhooksUpdate: self = .webhooksUpdate(try container.decode(DiscordWebhooksUpdateEvent.self, forKey: .data))
        case .applicationCommandCreate: self = .applicationCommandCreate(try container.decode(DiscordApplicationCommandCreateEvent.self, forKey: .data))
        case .applicationCommandUpdate: self = .applicationCommandUpdate(try container.decode(DiscordApplicationCommandUpdateEvent.self, forKey: .data))
        case .interactionCreate: self = .interactionCreate(try container.decode(DiscordInteractionCreateEvent.self, forKey: .data))
        }
    }
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

    // Interactions

    public static let interactionCreate = DiscordDispatchEventType(rawValue: "INTERACTION_CREATE")

    public init(rawValue: String) {
        self.rawValue = rawValue
    }
}

public typealias DiscordChannelCreateEvent = DiscordChannel
public typealias DiscordChannelUpdateEvent = DiscordChannel
public typealias DiscordChannelDeleteEvent = DiscordChannel
public typealias DiscordThreadCreateEvent = DiscordChannel
public typealias DiscordThreadUpdateEvent = DiscordChannel
public typealias DiscordThreadDeleteEvent = DiscordChannel

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
    public var gatewayVersion: Int

    /// Information about the user including email.
    public var user: DiscordUser

    /// The guilds the user is in
    public var guilds: [DiscordUnavailableGuild]

    /// Used for resuming connections.
    public var sessionId: String

    /// The shard information associated with this session, if sent
    /// when identifying. An array of two integers:
    /// - shard_id
    /// - num_shards
    public var shard: [Int]

    /// The partial application object (contains `id` and `flags`).
    public var application: DiscordApplication
}
