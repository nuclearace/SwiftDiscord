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
public struct DiscordMessage: ExpressibleByStringLiteral, Identifiable, Codable {
    // Used for `createDataForSending`
    private struct Draft: Codable {
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
        case referencedMessage = "referenced_message"
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

    /// The activity for this message, if any.
    public let activity: Activity?

    /// Sent with Rich-Presence messages.
    public let application: DiscordApplication?

    /// The attachments included in this message.
    public let attachments: [DiscordAttachment]

    /// Who sent this message.
    public let author: DiscordUser?

    /// The snowflake id of the channel this message is on.
    public let channelId: ChannelID

    /// The content of this message.
    public let content: String

    /// When this message was last edited.
    public let editedTimestamp: Date

    /// The embeds that are in this message.
    public let embeds: [DiscordEmbed]

    /// The snowflake id of this message.
    public let id: MessageID

    /// Whether or not this message mentioned everyone.
    public let mentionEveryone: Bool

    /// List of snowflake ids of roles that were mentioned in this message.
    public let mentionRoles: [RoleID]

    /// List of users that were mentioned in this message.
    public let mentions: [DiscordUser]

    /// Used for validating a message was sent.
    public let nonce: Snowflake

    /// Whether this message is pinned.
    public let pinned: Bool

    /// The reactions a message has.
    public let reactions: [DiscordReaction]

    /// The stickers a message has.
    public let stickers: [DiscordSticker]

    /// The timestamp of this message.
    public let timestamp: Date

    /// Whether or not this message should be read by a screen reader.
    public let tts: Bool

    /// Finer-grained control over the allowed mentions in an outgoing message.
    public let allowedMentions: DiscordAllowedMentions?

    /// A referenced message in an incoming message. Only present if it's a reply.
    @CodableBox public var referencedMessage: DiscordMessage?

    /// A referenced message in an outgoing message.
    public let messageReference: DiscordMessageReference?

    /// Interactive components in the message. This top-level array should only
    /// contain action rows (which can then e.g. contain buttons).
    public let components: [DiscordMessageComponent]?

    /// The type of this message.
    public let type: DiscordMessageType

    let files: [DiscordFileUpload]

    // MARK: Initializers

    ///
    /// Creates a message that can be used to send.
    ///
    /// - parameter content: The content of this message.
    /// - parameter embeds: The embeds for this message.
    /// - parameter files: The files to send with this message.
    /// - parameter tts: Whether this message should be text-to-speach.
    ///
    public init(
        content: String,
        embed: DiscordEmbed? = nil,
        files: [DiscordFileUpload] = [],
        tts: Bool = false,
        allowedMentions: DiscordAllowedMentions? = nil,
        messageReference: DiscordMessageReference? = nil,
        components: [DiscordMessageComponent] = []
    ) {
        self.content = content
        if let embed = embed {
            self.embeds = [embed]
        } else {
            self.embeds = []
        }
        self.activity = nil
        self.application = nil
        self.files = files
        self.tts = tts
        self.allowedMentions = allowedMentions
        self.messageReference = messageReference
        self.components = components
        self._referencedMessage = .init(wrappedValue: nil)
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
            content: content,
            tts: tts,
            embed: embeds.first,
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
    public struct Activity: Codable {
        /// Represents the type of activity.
        public enum ActivityType: Int, Codable {
            /// Join.
            case join = 1

            /// Spectate.
            case spectate

            /// Listen.
            case listen

            /// Join request.
            case joinRequest
        }

        public enum CodingKeys: String, CodingKey {
            case type
            case partyId = "party_id"
        }

        /// The type of action.
        public let type: ActivityType

        // FIXME Make Par†yId type?
        /// The party ID for this activity
        public let partyId: String?
    }
}

/// Type of message
public enum DiscordMessageType: Int, Codable {
    /// Default.
    case `default` = 0

    /// Recipient Add.
    case recipientAdd = 1

    /// Recipient Remove.
    case recipientRemove = 2

    /// Call.
    case call = 3

    /// Channel name change.
    case channelNameChange = 4

    /// Channel icon change.
    case channelIconChange = 5

    /// Channel pinned message.
    case channelPinnedMessage = 6

    /// Guild member join.
    case guildMemberJoin = 7

    /// User premium guild subscription.
    case userPremiumGuildSubscription = 8

    /// User premium guild subscription tier 1.
    case userPremiumGuildSubscriptionTier1 = 9

    /// User premium guild subscription tier 2.
    case userPremiumGuildSubscriptionTier2 = 10

    /// User premium guild subscription tier 3.
    case userPremiumGuildSubscriptionTier3 = 11

    /// Channel follow add.
    case channelFollowAdd = 12

    /// Guild discovery disqualified.
    case guildDiscoveryDisqualified = 14

    /// Guild discovery requalified.
    case guildDiscoveryRequalified = 15

    /// Message reply.
    case reply = 19
}

/// Represents a message reaction.
public struct DiscordReaction: Codable {
    // MARK: Properties

    /// The number of times this emoji has been used to react.
    public let count: Int

    /// Whether the current user reacted with this emoji.
    public let me: Bool

    /// The emoji used to react.
    public let emoji: DiscordEmoji
}

public enum DiscordAllowedMentionType: String, Codable {
    case roles
    case users
    case everyone
}

/// Allows for more granular control over mentions
/// without having to modify the message content.
public struct DiscordAllowedMentions: Codable {
    public enum CodingKeys : String, CodingKey {
        case parse
        case roles
        case users
        case repliedUser = "replied_user"
    }

    /// An array of allowed mentions types to parse from the content.
    public let parse: DiscordAllowedMentionType
    /// Array of role ids to mention.
    public let roles: [RoleID]
    /// Array of user ids to mention.
    public let users: [UserID]
    /// For replies, whether to mention the author of the message being replied to (default: false)
    public let repliedUser: Bool

    public init(parse: DiscordAllowedMentionType = .everyone, roles: [RoleID] = [], users: [UserID] = [], repliedUser: Bool = false) {
        self.parse = parse
        self.roles = roles
        self.users = users
        self.repliedUser = repliedUser
    }
}

/// A reference to a message, e.g. used in outgoing replies.
public struct DiscordMessageReference: Codable {
    public enum CodingKeys : String, CodingKey {
        case messageId = "message_id"
        case channelId = "channel_id"
        case guildId = "guild_id"
    }

    public let messageId: MessageID?
    public let channelId: ChannelID?
    public let guildId: GuildID?

    public init(messageId: MessageID? = nil, channelId: ChannelID? = nil, guildId: GuildID? = nil) {
        self.messageId = messageId
        self.channelId = channelId
        self.guildId = guildId
    }
}

/// An interactive part of a message.
public struct DiscordMessageComponent: Codable {
    public enum CodingKeys : String, CodingKey {
        case type
        case components
        case style
        case label
        case emoji
        case customId = "custom_id"
        case url
        case disabled
    }

    /// The type of the component.
    public let type: DiscordMessageComponentType
    /// Sub-components. Only valid for action rows.
    public let components: [DiscordMessageComponent]?
    /// One of a few button styles. Only valid for buttons.
    public let style: DiscordMessageComponentButtonStyle?
    /// Label that appears on a button. Only valid for buttons.
    public let label: String?
    /// Emoji that appears on the button. Only valid for buttons.
    public let emoji: DiscordMessageComponentEmoji?
    /// A developer-defined id for the button, max 100 chars. Only valid for buttons.
    public let customId: String?
    /// A URL for link-style buttons. Only valid for buttons.
    public let url: URL?
    /// Whether the button is disabled. False by default. Only valid for buttons.
    public let disabled: Bool?

    public init(
        type: DiscordMessageComponentType,
        components: [DiscordMessageComponent]? = nil,
        style: DiscordMessageComponentButtonStyle? = nil,
        label: String? = nil,
        emoji: DiscordMessageComponentEmoji? = nil,
        customId: String? = nil,
        url: URL? = nil,
        disabled: Bool? = nil
    ) {
        self.type = type
        self.components = components
        self.style = style
        self.label = label
        self.emoji = emoji
        self.customId = customId
        self.url = url
        self.disabled = disabled
    }

    /// Creates a new button component.
    public static func button(
        style: DiscordMessageComponentButtonStyle? = nil,
        label: String? = nil,
        emoji: DiscordMessageComponentEmoji? = nil,
        customId: String? = nil,
        url: URL? = nil,
        disabled: Bool? = nil
    ) -> DiscordMessageComponent {
        DiscordMessageComponent(
            type: .button,
            style: style,
            label: label,
            emoji: emoji,
            customId: customId,
            url: url,
            disabled: disabled
        )
    }

    /// Creates a new action row component. Cannot contain other action rows.
    public static func actionRow(components: [DiscordMessageComponent]) -> DiscordMessageComponent {
        DiscordMessageComponent(
            type: .actionRow,
            components: components
        )
    }
}

public struct DiscordMessageComponentType : RawRepresentable, Hashable, Codable {
    public let rawValue: Int

    public static let actionRow = DiscordMessageComponentType(rawValue: 1)
    public static let button = DiscordMessageComponentType(rawValue: 2)

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
}

/// A partial emoji for use in message components.
public struct DiscordMessageComponentEmoji: Codable, Identifiable {
    public let id: EmojiID?
    public let name: String?
    public let animated: Bool

    public init(id: EmojiID? = nil, name: String? = nil, animated: Bool = false) {
        self.id = id
        self.name = name
        self.animated = animated
    }
}

public struct DiscordMessageComponentButtonStyle: RawRepresentable, Hashable, Codable {
    public let rawValue: Int

    public static let primary = DiscordMessageComponentButtonStyle(rawValue: 1)
    public static let secondary = DiscordMessageComponentButtonStyle(rawValue: 2)
    public static let success = DiscordMessageComponentButtonStyle(rawValue: 3)
    public static let danger = DiscordMessageComponentButtonStyle(rawValue: 4)
    public static let link = DiscordMessageComponentButtonStyle(rawValue: 5)

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
}
