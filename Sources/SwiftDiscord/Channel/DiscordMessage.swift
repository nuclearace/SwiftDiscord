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

import Foundation

/// Represents a Discord chat message.
public struct DiscordMessage : DiscordClientHolder, ExpressibleByStringLiteral {
    // Used for `createDataForSending`
    private struct FieldsList : Encodable {
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

    // MARK: Typealiases

    /// ExpressibleByStringLiteral conformance
    public typealias StringLiteralType = String

    /// ExpressibleByStringLiteral conformance.
    public typealias ExtendedGraphemeClusterLiteralType = String.ExtendedGraphemeClusterLiteralType

    /// ExpressibleByStringLiteral conformance.
    public typealias UnicodeScalarLiteralType = String.UnicodeScalarLiteralType

    // MARK: Properties

    /// The activity for this message, if any.
    public let activity: MessageActivity?

    /// Sent with Rich-Presence messages.
    public let application: MessageApplication?

    /// The attachments included in this message.
    public let attachments: [DiscordAttachment]

    /// Who sent this message.
    public let author: DiscordUser

    /// The snowflake id of the channel this message is on.
    public let channelId: ChannelID

    /// A reference to the client.
    public weak var client: DiscordClient?

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
    public let stickers: [DiscordMessageSticker]

    /// The timestamp of this message.
    public let timestamp: Date

    /// Whether or not this message should be read by a screen reader.
    public let tts: Bool

    /// Finer-grained control over the allowed mentions in an outgoing message.
    public let allowedMentions: DiscordAllowedMentions?

    /// A referenced message in an incoming message. Only present if it's a reply.
    ///
    /// TODO: This is actually a DiscordMessage object too, but would cause the
    ///       value type to become recursive, which is not allowed yet (since optionals
    ///       are value types themselves that do not box the value).
    public let referencedMessage: [String: Any]?

    /// A referenced message in an outgoing message.
    public let messageReference: DiscordMessageReference?

    /// Interactive components in the message. This top-level array should only
    /// contain action rows (which can then e.g. contain buttons).
    public let components: [DiscordMessageComponent]?

    /// The type of this message.
    public let type: MessageType

    /// The channel that this message originated from. Can return nil if the channel couldn't be found.
    public var channel: DiscordTextChannel? {
        return client?.findChannel(fromId: channelId) as? DiscordTextChannel
    }

    /// Returns a `DiscordGuildMember` for this author, or nil if this message is not from a guild.
    public var guildMember: DiscordGuildMember? {
        // TODO cache this
        guard let guild = channel?.guild else { return nil }

        return guild.members[author.id]
    }

    let files: [DiscordFileUpload]

    // MARK: Initializers

    init(messageObject: [String: Any], client: DiscordClient?) {
        activity = MessageActivity(activityObject: messageObject.get("activity", as: [String: Any].self))
        application = MessageApplication(applicationObject: messageObject.get("application", as: [String: Any].self))
        attachments = DiscordAttachment.attachmentsFromArray(messageObject.get("attachments", or: JSONArray()))
        author = DiscordUser(userObject: messageObject.get("author", or: [String: Any]()))
        channelId = Snowflake(messageObject["channel_id"] as? String) ?? 0
        content = messageObject.get("content", or: "")
        embeds = DiscordEmbed.embedsFromArray(messageObject.get("embeds", or: JSONArray()))
        id = messageObject.getSnowflake()
        mentionEveryone = messageObject.get("mention_everyone", or: false)
        mentionRoles = messageObject.get("mention_roles", or: [String]()).compactMap(Snowflake.init)
        mentions = DiscordUser.usersFromArray(messageObject.get("mentions", or: JSONArray()))
        nonce = messageObject.getSnowflake(key: "nonce")
        pinned = messageObject.get("pinned", or: false)
        reactions = DiscordReaction.reactionsFromArray(messageObject.get("reactions", or: []))
        stickers = DiscordMessageSticker.stickersFromArray(messageObject.get("sticker", or: []))
        tts = messageObject.get("tts", or: false)
        editedTimestamp = DiscordDateFormatter.format(messageObject.get("edited_timestamp", or: "")) ?? Date()
        timestamp = DiscordDateFormatter.format(messageObject.get("timestamp", or: "")) ?? Date()
        allowedMentions = nil
        referencedMessage = messageObject.get("referenced_message", as: [String: Any].self)
        messageReference = nil
        components = nil
        files = []
        type = MessageType(rawValue: messageObject.get("type", or: 0)) ?? .default
        self.client = client
    }

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
        self.referencedMessage = nil
        self.attachments = []
        self.author = DiscordUser(userObject: [:])
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
        let fields = FieldsList(
            content: content,
            tts: tts,
            embed: embeds.first,
            allowedMentions: allowedMentions,
            messageReference: messageReference,
            components: components
        )
        let fieldsData = JSON.encodeJSONData(fields) ?? Data()
        if files.count > 0 {
            return .right(createMultipartBody(encodedJSON: fieldsData, files: files))
        } else {
            return .left(fieldsData)
        }
    }

    ///
    /// Deletes this message from Discord.
    ///
    public func delete() {
        channel?.deleteMessage(self)
    }

    static func messagesFromArray(_ array: [[String: Any]]) -> [DiscordMessage] {
        return array.map({ DiscordMessage(messageObject: $0, client: nil) })
    }
}

public extension DiscordMessage {
    /// Type of message
    enum MessageType : Int {
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

    /// Represents an action that be taken on a message.
    struct MessageActivity {
        /// Represents the type of activity.
        public enum ActivityType : Int {
            /// Join.
            case join = 1

            /// Spectate.
            case spectate

            /// Listen.
            case listen

            /// Join request.
            case joinRequest
        }

        /// The type of action.
        public let type: ActivityType

        // FIXME Make Par†yId type?
        /// The party ID for this activity
        public let partyId: String?
    }

    /// Represents an application in a `DiscordMessage` object.
    struct MessageApplication {
        /// The id of this application.
        public let id: Snowflake

        /// Id of the embed's image asset.
        public let coverImage: String

        /// The description of the application.
        public let description: String

        /// Id of the application's icon.
        public let icon: String

        /// The name of the application.
        public let name: String
    }
}

extension DiscordMessage.MessageActivity {
    init?(activityObject: [String: Any]?) {
        guard let activityObject = activityObject else { return nil }

        type = ActivityType(rawValue: activityObject.get("type", or: 0)) ?? .join
        partyId = activityObject.get("party_id", as: String.self)
    }
}

extension DiscordMessage.MessageApplication {
    init?(applicationObject: [String: Any]?) {
        guard let applicationObject = applicationObject else { return nil }

        id = applicationObject.getSnowflake(key: "id")
        coverImage = applicationObject.get("cover_image", or: "")
        description = applicationObject.get("description", or: "")
        icon = applicationObject.get("icon", or: "")
        name = applicationObject.get("name", or: "")
    }
}

/// Represents an attachment.
public struct DiscordAttachment {
    // MARK: Properties

    /// The snowflake id of this attachment.
    public let id: AttachmentID

    /// The name of the file.
    public let filename: String

    /// The height, if this is an image.
    public let height: Int?

    /// The proxy url for this attachment.
    public let proxyUrl: URL

    /// The size of this attachment.
    public let size: Int

    /// The url of this attachment.
    public let url: URL

    /// The width, if this is an image.
    public let width: Int?

    init(attachmentObject: [String: Any]) {
        id = attachmentObject.getSnowflake()
        filename = attachmentObject.get("filename", or: "")
        height = attachmentObject["height"] as? Int
        proxyUrl = URL(string: attachmentObject.get("proxy_url", or: "")) ?? URL.localhost
        size = attachmentObject.get("size", or: 0)
        url = URL(string: attachmentObject.get("url", or: "")) ?? URL.localhost
        width = attachmentObject["width"] as? Int
    }

    static func attachmentsFromArray(_ attachmentArray: [[String: Any]]) -> [DiscordAttachment] {
        return attachmentArray.map(DiscordAttachment.init)
    }
}

/// Represents an embeded entity.
public struct DiscordEmbed : Encodable {
    var shouldIncludeNilsInJSON: Bool { return false }
    // MARK: Nested Types

    /// Represents an Embed's author.
    public struct Author : Encodable {
        private enum CodingKeys : String, CodingKey {
            case name
            case iconUrl = "icon_url"
            case proxyIconUrl = "proxy_icon_url"
            case url
        }
        // MARK: Properties

        /// The name for this author.
        public var name: String

        /// The icon for this url.
        public var iconUrl: URL?

        /// The proxy url for the icon.
        public let proxyIconUrl: URL?

        /// The url of this author.
        public var url: URL?

        ///
        /// Creates an Author object.
        ///
        /// - parameter name: The name of this author.
        /// - parameter iconUrl: The iconUrl for this author's icon.
        /// - parameter url: The url for this author.
        ///
        public init(name: String, iconUrl: URL? = nil, url: URL? = nil) {
            self.name = name
            self.iconUrl = iconUrl
            self.url = url
            self.proxyIconUrl = nil
        }

        /// For testing
        init(name: String, iconURL: URL?, url: URL?, proxyIconURL: URL?) {
            self.name = name
            self.iconUrl = iconURL
            self.url = url
            self.proxyIconUrl = proxyIconURL
        }
    }

    /// Represents an Embed's fields.
    public struct Field : Encodable {
        // MARK: Properties

        /// The name of the field.
        public var name: String

        /// The value of the field.
        public var value: String

        /// Whether this field should be inlined
        public var inline: Bool

        // MARK: Initializers

        ///
        /// Creates a Field object.
        ///
        /// - parameter name: The name of this field.
        /// - parameter value: The value of this field.
        /// - parameter inline: Whether this field can be inlined.
        ///
        public init(name: String, value: String, inline: Bool = false) {
            self.name = name
            self.value = value
            self.inline = inline
        }
    }

    /// Represents an Embed's footer.
    public struct Footer : Encodable {
        private enum CodingKeys : String, CodingKey {
            case text
            case iconUrl = "icon_url"
            case proxyIconUrl = "proxy_icon_url"
        }
        // MARK: Properties

        /// The text for this footer.
        public var text: String?

        /// The icon for this url.
        public var iconUrl: URL?

        /// The proxy url for the icon.
        public let proxyIconUrl: URL?

        ///
        /// Creates a Footer object.
        ///
        /// - parameter text: The text of this field.
        /// - parameter iconUrl: The iconUrl of this field.
        ///
        public init(text: String?, iconUrl: URL? = nil) {
            self.text = text
            self.iconUrl = iconUrl
            self.proxyIconUrl = nil
        }

        /// For testing
        init(text: String?, iconURL: URL?, proxyIconURL: URL?) {
            self.text = text
            self.iconUrl = iconURL
            self.proxyIconUrl = proxyIconURL
        }
    }

    /// Represents an Embed's image.
    public struct Image : Encodable {
        // MARK: Properties

        /// The height of this image.
        public let height: Int

        /// The url of this image.
        public var url: URL

        /// The width of this image.
        public let width: Int

        ///
        /// Creates an Image object.
        ///
        /// - parameter url: The url for this field.
        ///
        public init(url: URL) {
            self.height = -1
            self.url = url
            self.width = -1
        }

        /// For Testing
        init(url: URL, width: Int, height: Int) {
            self.url = url
            self.width = width
            self.height = height
        }
    }

    /// Represents what is providing the content of an embed.
    public struct Provider : Encodable {
        // MARK: Properties

        /// The name of this provider.
        public let name: String

        /// The url of this provider.
        public let url: URL?
    }

    /// Represents the thumbnail of an embed.
    public struct Thumbnail : Encodable {
        private enum CodingKeys : String, CodingKey {
            case height
            case proxyUrl = "proxy_url"
            case url
            case width
        }
        // MARK: Properties

        /// The height of this image.
        public let height: Int

        /// The proxy url for this image.
        public let proxyUrl: URL?

        /// The url for this image.
        public var url: URL

        /// The width of this image.
        public let width: Int

        ///
        /// Creates a Thumbnail object.
        ///
        /// - parameter url: The url for this field
        ///
        public init(url: URL) {
            self.url = url
            self.height = -1
            self.width = -1
            self.proxyUrl = nil
        }

        /// For testing
        init(url: URL, width: Int, height: Int, proxyURL: URL?) {
            self.url = url
            self.width = width
            self.height = height
            self.proxyUrl = proxyURL
        }
    }

    /// Represents the video of an embed.
    /// Note: Discord does not accept these, so they are read-only
    public struct Video : Encodable {

        /// The height of this video
        public let height: Int

        /// The url for this video
        public let url: URL

        /// The width of this video
        public let width: Int
    }

    // MARK: Properties

    /// The author of this embed.
    public var author: Author?

    /// The color of this embed.
    public var color: Int?

    /// The description of this embed.
    public var description: String?

    /// The footer for this embed.
    public var footer: Footer?

    /// The image for this embed.
    public var image: Image?

    /// The provider of this embed.
    public let provider: Provider?

    /// The thumbnail of this embed.
    public var thumbnail: Thumbnail?

    /// The timestamp of this embed.
    public var timestamp: Date?

    /// The title of this embed.
    public var title: String?

    /// The type of this embed.
    public let type: String

    /// The url of this embed.
    public var url: URL?

    /// The video of this embed.
    /// This is read-only, as bots cannot embed videos
    public var video: Video?

    /// The embed's fields
    public var fields: [Field]

    // MARK: Initializers

    ///
    /// Creates an Embed object.
    ///
    /// - parameter title: The title of this embed.
    /// - parameter description: The description of this embed.
    /// - parameter author: The author of this embed.
    /// - parameter url: The url for this embed, if there is one.
    /// - parameter image: The image for the embed, if there is one.
    /// - parameter timestamp: The timestamp of this embed, if there is one.
    /// - parameter thumbnail: The thumbnail of this embed, if there is one.
    /// - parameter color: The color of this embed.
    /// - parameter footer: The footer for this embed, if there is one.
    /// - parameter fields: The list of fields for this embed, if there are any.
    ///
    public init(title: String? = nil,
                description: String? = nil,
                author: Author? = nil,
                url: URL? = nil,
                image: Image? = nil,
                timestamp: Date? = nil,
                thumbnail: Thumbnail? = nil,
                color: Int? = nil,
                footer: Footer? = nil,
                fields: [Field] = []) {
        self.title = title
        self.author = author
        self.description = description
        self.provider = nil
        self.thumbnail = thumbnail
        self.timestamp = timestamp
        self.type = "rich"
        self.url = url
        self.image = image
        self.color = color
        self.footer = footer
        self.fields = fields
    }

    init(embedObject: [String: Any]) {
        author = Author(authorObject: embedObject.get("author", or: nil))
        description = embedObject.get("description", or: nil)
        provider = Provider(providerObject: embedObject.get("provider", or: nil))
        timestamp = embedObject.get("timestamp", as: String.self).flatMap(DiscordDateFormatter.format)
        thumbnail = Thumbnail(thumbnailObject: embedObject.get("thumbnail", or: nil))
        title = embedObject.get("title", or: nil)
        type = embedObject.get("type", or: "")
        url = URL(string: embedObject.get("url", or: ""))
        image = Image(imageObject: embedObject.get("image", or: nil))
        fields = Field.fieldsFromArray(embedObject.get("fields", or: []))
        color = embedObject.get("color", or: nil)
        footer = Footer(footerObject: embedObject.get("footer", or: nil))
        video = Video(videoObject: embedObject.get("video", or: nil))
    }

    static func embedsFromArray(_ embedsArray: [[String: Any]]) -> [DiscordEmbed] {
        return embedsArray.map(DiscordEmbed.init)
    }
}

extension DiscordEmbed.Field {
    init(fieldObject: [String: Any]) {
        name = fieldObject.get("name", or: "")
        value = fieldObject.get("value", or: "")
        inline = fieldObject.get("inline", or: false)
    }

    static func fieldsFromArray(_ fieldArray: [[String: Any]]) -> [DiscordEmbed.Field] {
        return fieldArray.map(DiscordEmbed.Field.init(fieldObject:))
    }
}

extension DiscordEmbed.Author {
    init?(authorObject: [String: Any]?) {
        guard let authorObject = authorObject else { return nil }

        name = authorObject.get("name", or: "")
        iconUrl = URL(string: authorObject.get("icon_url", or: ""))
        proxyIconUrl = URL(string: authorObject.get("proxy_icon_url", or: ""))
        url = URL(string: authorObject.get("url", or: ""))
    }
}

extension DiscordEmbed.Footer {
    init?(footerObject: [String: Any]?) {
        guard let footerObject = footerObject else { return nil }

        text = footerObject.get("text", or: "")
        iconUrl = URL(string: footerObject.get("icon_url", or: ""))
        proxyIconUrl = URL(string: footerObject.get("proxy_icon_url", or: ""))
    }
}

extension DiscordEmbed.Image {
    init?(imageObject: [String: Any]?) {
        guard let imageObject = imageObject else { return nil }

        height = imageObject.get("height", or: -1)
        url = URL(string: imageObject.get("url", or: "")) ?? URL.localhost
        width = imageObject.get("width", or: -1)
    }
}

extension DiscordEmbed.Provider {
    init?(providerObject: [String: Any]?) {
        guard let providerObject = providerObject else { return nil }

        name = providerObject.get("name", or: "")
        url = URL(string: providerObject.get("url", or: ""))
    }
}

extension DiscordEmbed.Thumbnail {
    init?(thumbnailObject: [String: Any]?) {
        guard let thumbnailObject = thumbnailObject else { return nil }

        height = thumbnailObject.get("height", or: 0)
        proxyUrl = URL(string: thumbnailObject.get("proxy_url", or: ""))
        url = URL(string: thumbnailObject.get("url", or: "")) ?? URL.localhost
        width = thumbnailObject.get("width", or: 0)
    }
}

extension DiscordEmbed.Video {
    init?(videoObject: [String: Any]?) {
        guard let videoObject = videoObject else { return nil }

        height = videoObject.get("height", or: 0)
        url = videoObject.get("url", as: String.self).flatMap(URL.init) ?? URL.localhost
        width = videoObject.get("width", or: 0)
    }
}

/// Represents a file to be uploaded to Discord.
public struct DiscordFileUpload {
    // MARK: Properties

    /// The file data.
    public let data: Data

    /// The filename.
    public let filename: String

    /// The mime type.
    public let mimeType: String

    // MARK: Initializers

    ///
    /// Constructs a new DiscordFileUpload.
    ///
    /// - parameter data: The file data
    /// - parameter filename: The filename
    /// - parameter mimeType: The mime type
    ///
    public init(data: Data, filename: String, mimeType: String) {
        self.data = data
        self.filename = filename
        self.mimeType = mimeType
    }
}

/// Represents a message reaction.
public struct DiscordReaction {
    // MARK: Properties

    /// The number of times this emoji has been used to react.
    public let count: Int

    /// Whether the current user reacted with this emoji.
    public let me: Bool

    /// The emoji used to react.
    public let emoji: DiscordEmoji

    init(reactionObject: [String: Any]) {
        count = reactionObject.get("count", or: -1)
        me = reactionObject.get("me", or: false)
        emoji = DiscordEmoji(emojiObject: reactionObject.get("emoji", or: [:]))
    }

    static func reactionsFromArray(_ reactionsArray: [[String: Any]]) -> [DiscordReaction] {
        return reactionsArray.map(DiscordReaction.init)
    }
}

public enum DiscordAllowedMentionType : String, Encodable {
    case roles
    case users
    case everyone
}

/// Allows for more granular control over mentions
/// without having to modify the message content.
public struct DiscordAllowedMentions : Encodable {
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
public struct DiscordMessageReference : Encodable {
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
public struct DiscordMessageComponent : Encodable {
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

public struct DiscordMessageComponentType : RawRepresentable, Hashable, Encodable {
    public let rawValue: Int

    public static let actionRow = DiscordMessageComponentType(rawValue: 1)
    public static let button = DiscordMessageComponentType(rawValue: 2)

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
}

/// A partial emoji for use in message components.
public struct DiscordMessageComponentEmoji : Encodable {
    public let id: EmojiID?
    public let name: String?
    public let animated: Bool

    public init(id: EmojiID? = nil, name: String? = nil, animated: Bool = false) {
        self.id = id
        self.name = name
        self.animated = animated
    }
}

public struct DiscordMessageComponentButtonStyle : RawRepresentable, Hashable, Encodable {
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

public enum DiscordMessageStickerFormatType: Int {
    case png = 1
    case apng = 2
    case lottie = 3
}

public struct DiscordMessageSticker {
    /// ID of the sticker
    public let id: Snowflake
    /// ID of the sticker pack
    public let packId: Snowflake
    /// Name of the sticker
    public let name: String
    /// Description of the sticker
    public let description: String
    /// List of tags for the sticker
    public let tags: [String]
    /// Sticker asset hash
    public let asset: String?
    /// Sticker preview asset hash
    public let previewAsset: String?
    /// Type of sticker format
    public let formatType: DiscordMessageStickerFormatType?

    init(stickerObject: [String: Any]) {
        id = stickerObject.getSnowflake(key: "id")
        packId = stickerObject.getSnowflake(key: "pack_id")
        name = stickerObject.get("name", or: "")
        description = stickerObject.get("description", or: "")
        tags = stickerObject.get("tags", or: "").split(separator: ",").map(String.init)
        asset = stickerObject.get("asset", as: String.self)
        previewAsset = stickerObject.get("preview_asset", as: String.self)
        formatType = stickerObject.get("format_type", as: Int.self).flatMap(DiscordMessageStickerFormatType.init(rawValue:))
    }

    static func stickersFromArray(_ stickerArray: [[String: Any]]) -> [DiscordMessageSticker] {
        return stickerArray.map(DiscordMessageSticker.init)
    }
}
