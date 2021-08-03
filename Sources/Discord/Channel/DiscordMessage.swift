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

/// Represents a Discord chat message.
public struct DiscordMessage: ExpressibleByStringLiteral, Identifiable, Codable, Hashable {
    // Used for `createDataForSending`
    private struct Draft: Codable, Hashable {
        enum CodingKeys: String, CodingKey {
            case content
            case tts
            case embed
            case allowedMentions = "allowed_mentions"
            case messageReference = "message_reference"
            case components
        }

        let content: String
        let tts: Bool
        let embed: DiscordEmbed?
        let allowedMentions: DiscordAllowedMentions?
        let messageReference: DiscordMessageReference?
        let components: [DiscordMessageComponent]?
    }

    public enum CodingKeys: String, CodingKey {
        case activity
        case application
        case attachments
        case author
        case channelId = "channel_id"
        case guildId = "guild_id"
        case content
        case embeds
        case id
        case mentionEveryone = "mention_everyone"
        case mentionRoles = "mention_roles"
        case mentions
        case nonce
        case pinned
        case reactions
        case stickers
        case tts
        case editedTimestamp = "edited_timestamp"
        case timestamp
        case allowedMentions = "allowed_mentions"
        case _referencedMessage = "referenced_message"
        case components
        case type
    }

    // MARK: Typealiases

    /// ExpressibleByStringLiteral conformance
    public typealias StringLiteralType = String

    /// ExpressibleByStringLiteral conformance.
    public typealias ExtendedGraphemeClusterLiteralType = String.ExtendedGraphemeClusterLiteralType

    /// ExpressibleByStringLiteral conformance.
    public typealias UnicodeScalarLiteralType = String.UnicodeScalarLiteralType

    // MARK: Properties

    /// The snowflake id of this message.
    public var id: MessageID

    /// The type of this message.
    public var type: DiscordMessageType? = nil

    /// The activity for this message, if any.
    public var activity: Activity? = nil

    /// Sent with Rich-Presence messages.
    public var application: DiscordApplication? = nil

    /// The attachments included in this message.
    public var attachments: [DiscordAttachment]? = nil

    /// Who sent this message.
    public var author: DiscordUser? = nil

    /// The snowflake id of the channel this message is on.
    public var channelId: ChannelID

    /// The snowflake id of the guild this message is on.
    public var guildId: GuildID? = nil

    /// The content of this message.
    public var content: String? = nil

    /// When this message was last edited.
    public var editedTimestamp: Date? = nil

    /// The embeds that are in this message.
    public var embeds: [DiscordEmbed]? = nil

    /// Whether or not this message mentioned everyone.
    public var mentionEveryone: Bool? = nil

    /// List of snowflake ids of roles that were mentioned in this message.
    public var mentionRoles: [RoleID]? = nil

    /// List of users that were mentioned in this message.
    public var mentions: [DiscordUser]? = nil

    /// Used for validating a message was sent.
    public var nonce: Snowflake? = nil

    /// Whether this message is pinned.
    public var pinned: Bool? = nil

    /// The reactions a message has.
    public var reactions: [DiscordReaction]? = nil

    /// The stickers a message has.
    public var stickers: [DiscordSticker]? = nil

    /// The timestamp of this message.
    public var timestamp: Date? = nil

    /// Whether or not this message should be read by a screen reader.
    public var tts: Bool? = nil

    /// Finer-grained control over the allowed mentions in an outgoing message.
    public var allowedMentions: DiscordAllowedMentions? = nil

    /// A referenced message in an incoming message. Only present if it's a reply.
    public var _referencedMessage: CodableBox<DiscordMessage>? = nil

    /// A referenced message in an incoming message. Only present if it's a reply.
    public var referencedMessage: DiscordMessage? {
        get { _referencedMessage?.wrappedValue }
        set { _referencedMessage = newValue.map { .init(wrappedValue: $0) } }
    }

    /// A referenced message in an outgoing message.
    public var messageReference: DiscordMessageReference? = nil

    /// Interactive components in the message. This top-level array should only
    /// contain action rows (which can then e.g. contain buttons).
    public var components: [DiscordMessageComponent]? = nil

    /// Files to be uploaded as part of an outgoing message.
    public var files: [DiscordFileUpload] = []

    // MARK: Initializers

    ///
    /// Creates an incoming message.
    ///
    /// This is only used internally for testing, the actual
    /// messages from Discord will use the Decoder-based initializer.
    ///
    init(
        id: MessageID,
        type: DiscordMessageType? = nil,
        activity: Activity? = nil,
        application: DiscordApplication? = nil,
        attachments: [DiscordAttachment] = [],
        author: DiscordUser? = nil,
        channelId: ChannelID,
        guildId: GuildID? = nil,
        content: String? = nil,
        editedTimestamp: Date? = nil,
        embeds: [DiscordEmbed] = [],
        mentionEveryone: Bool? = nil,
        mentionRoles: [RoleID] = [],
        mentions: [DiscordUser] = [],
        nonce: Snowflake? = nil,
        pinned: Bool = false,
        reactions: [DiscordReaction] = [],
        stickers: [DiscordSticker] = [],
        timestamp: Date? = nil,
        tts: Bool = false,
        allowedMentions: DiscordAllowedMentions? = nil,
        referencedMessage: DiscordMessage? = nil,
        components: [DiscordMessageComponent]? = nil
    ) {
        self.id = id
        self.type = type
        self.activity = activity
        self.application = application
        self.attachments = attachments
        self.author = author
        self.channelId = channelId
        self.guildId = guildId
        self.content = content
        self.editedTimestamp = editedTimestamp
        self.embeds = embeds
        self.mentionEveryone = mentionEveryone
        self.mentionRoles = mentionRoles
        self.mentions = mentions
        self.nonce = nonce
        self.pinned = pinned
        self.reactions = reactions
        self.stickers = stickers
        self.timestamp = timestamp
        self.tts = tts
        self.allowedMentions = allowedMentions
        self._referencedMessage = referencedMessage.map { .init(wrappedValue: $0) }
        self.components = components
    }

    ///
    /// Creates an outgoing message (i.e. one that we can send
    /// to Discord).
    ///
    /// - parameter content: The content of this message.
    /// - parameter embeds: The embeds for this message.
    /// - parameter files: The files to send with this message.
    /// - parameter tts: Whether this message should be text-to-speach.
    ///
    public init(
        content: String = "",
        embed: DiscordEmbed? = nil,
        files: [DiscordFileUpload] = [],
        tts: Bool = false,
        allowedMentions: DiscordAllowedMentions? = nil,
        messageReference: DiscordMessageReference? = nil,
        components: [DiscordMessageComponent] = []
    ) {
        self.content = content
        self.embeds = embed.map { [$0] } ?? []
        self.activity = nil
        self.application = nil
        self.files = files
        self.tts = tts
        self.allowedMentions = allowedMentions
        self.messageReference = messageReference
        self.components = components
        self._referencedMessage = nil
        self.attachments = []
        self.author = nil
        self.channelId = 0
        self.id = 0
        self.mentionEveryone = false
        self.mentionRoles = []
        self.mentions = []
        self.nonce = 0
        self.pinned = false
        self.reactions = []
        self.stickers = []
        self.editedTimestamp = Date()
        self.timestamp = Date()
        self.type = .default
    }

    ///
    /// ExpressibleByStringLiteral conformance.
    ///
    /// - parameter unicodeScalarLiteral: The unicode scalar literal
    ///
    public init(unicodeScalarLiteral value: UnicodeScalarLiteralType) {
        self.init(stringLiteral: String(extendedGraphemeClusterLiteral: value))
    }

    ///
    /// ExpressibleByStringLiteral conformance.
    ///
    /// - parameter extendedGraphemeClusterLiteral: The grapheme scalar literal
    ///
    public init(extendedGraphemeClusterLiteral value: ExtendedGraphemeClusterLiteralType) {
        self.init(stringLiteral: String(extendedGraphemeClusterLiteral: value))
    }

    ///
    /// ExpressibleByStringLiteral conformance.
    ///
    /// - parameter stringLiteral: The string literal
    ///
    public init(stringLiteral value: StringLiteralType) {
        self.init(content: value)
    }

    // MARK: Methods

    func createDataForSending() -> Either<Data, (boundary: String, body: Data)> {
        let fields = Draft(
            content: content ?? "",
            tts: tts ?? false,
            embed: embeds?.first,
            allowedMentions: allowedMentions,
            messageReference: messageReference,
            components: components
        )
        let fieldsData = (try? DiscordJSON.makeEncoder().encode(fields)) ?? Data()
        if files.count > 0 {
            return .right(createMultipartBody(encodedJSON: fieldsData, files: files))
        } else {
            return .left(fieldsData)
        }
    }

    

    /// Represents an action that be taken on a message.
    public struct Activity: Codable, Hashable {
        /// Represents the type of activity.
        public struct ActivityType: RawRepresentable, Codable, Hashable {
            public var rawValue: Int

            public static let join = ActivityType(rawValue: 1)
            public static let spectate = ActivityType(rawValue: 2)
            public static let listen = ActivityType(rawValue: 3)
            public static let joinRequest = ActivityType(rawValue: 4)

            public init(rawValue: Int) {
                self.rawValue = rawValue
            }
        }

        public enum CodingKeys: String, CodingKey {
            case type
            case partyId = "party_id"
        }

        /// The type of action.
        public var type: ActivityType

        // FIXME Make Par†yId type?
        /// The party ID for this activity
        public var partyId: String?
    }
}

/// The type of a message.
public struct DiscordMessageType: RawRepresentable, Codable, Hashable {
    public var rawValue: Int

    /// Default.
    public static let `default` = DiscordMessageType(rawValue: 0)
    /// Recipient Add.
    public static let recipientAdd = DiscordMessageType(rawValue: 1)
    /// Recipient Remove.
    public static let recipientRemove = DiscordMessageType(rawValue: 2)
    /// Call.
    public static let call = DiscordMessageType(rawValue: 3)
    /// Channel name change.
    public static let channelNameChange = DiscordMessageType(rawValue: 4)
    /// Channel icon change.
    public static let channelIconChange = DiscordMessageType(rawValue: 5)
    /// Channel pinned message.
    public static let channelPinnedMessage = DiscordMessageType(rawValue: 6)
    /// Guild member join.
    public static let guildMemberJoin = DiscordMessageType(rawValue: 7)
    /// User premium guild subscription.
    public static let userPremiumGuildSubscription = DiscordMessageType(rawValue: 8)
    /// User premium guild subscription tier 1.
    public static let userPremiumGuildSubscriptionTier1 = DiscordMessageType(rawValue: 9)
    /// User premium guild subscription tier 2.
    public static let userPremiumGuildSubscriptionTier2 = DiscordMessageType(rawValue: 10)
    /// User premium guild subscription tier 3.
    public static let userPremiumGuildSubscriptionTier3 = DiscordMessageType(rawValue: 11)
    /// Channel follow add.
    public static let channelFollowAdd = DiscordMessageType(rawValue: 12)
    /// Guild discovery disqualified.
    public static let guildDiscoveryDisqualified = DiscordMessageType(rawValue: 14)
    /// Guild discovery requalified.
    public static let guildDiscoveryRequalified = DiscordMessageType(rawValue: 15)
    /// Message reply.
    public static let reply = DiscordMessageType(rawValue: 19)

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
}

/// Represents a message reaction.
public struct DiscordReaction: Codable, Hashable {
    // MARK: Properties

    /// The number of times this emoji has been used to react.
    public var count: Int

    /// Whether the current user reacted with this emoji.
    public var me: Bool

    /// The emoji used to react.
    public var emoji: DiscordEmoji
}

public enum DiscordAllowedMentionType: String, Codable, Hashable {
    case roles
    case users
    case everyone
}

/// Allows for more granular control over mentions
/// without having to modify the message content.
public struct DiscordAllowedMentions: Codable, Hashable {
    public enum CodingKeys : String, CodingKey {
        case parse
        case roles
        case users
        case repliedUser = "replied_user"
    }

    /// An array of allowed mentions types to parse from the content.
    public var parse: DiscordAllowedMentionType
    /// Array of role ids to mention.
    public var roles: [RoleID]
    /// Array of user ids to mention.
    public var users: [UserID]
    /// For replies, whether to mention the author of the message being replied to (default: false)
    public var repliedUser: Bool

    public init(parse: DiscordAllowedMentionType = .everyone, roles: [RoleID] = [], users: [UserID] = [], repliedUser: Bool = false) {
        self.parse = parse
        self.roles = roles
        self.users = users
        self.repliedUser = repliedUser
    }
}

/// A reference to a message, e.g. used in outgoing replies.
public struct DiscordMessageReference: Codable, Hashable {
    public enum CodingKeys : String, CodingKey {
        case messageId = "message_id"
        case channelId = "channel_id"
        case guildId = "guild_id"
    }

    public var messageId: MessageID?
    public var channelId: ChannelID?
    public var guildId: GuildID?

    public init(messageId: MessageID? = nil, channelId: ChannelID? = nil, guildId: GuildID? = nil) {
        self.messageId = messageId
        self.channelId = channelId
        self.guildId = guildId
    }
}
