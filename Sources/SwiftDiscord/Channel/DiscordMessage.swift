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
    // MARK: Typealiases

    /// ExpressibleByStringLiteral conformance
    public typealias StringLiteralType = String

    /// ExpressibleByStringLiteral conformance.
    public typealias ExtendedGraphemeClusterLiteralType = String.ExtendedGraphemeClusterLiteralType

    /// ExpressibleByStringLiteral conformance.
    public typealias UnicodeScalarLiteralType = String.UnicodeScalarLiteralType

    // MARK: Properties

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

    /// The timestamp of this message.
    public let timestamp: Date

    /// Whether or not this message should be read by a screen reader.
    public let tts: Bool

    /// The channel that this message originated from. Can return nil if the channel couldn't be found.
    public var channel: DiscordTextChannel? {
        return client?.findChannel(fromId: channelId) as? DiscordTextChannel
    }

    let files: [DiscordFileUpload]

    // MARK: Initializers

    init(messageObject: [String: Any], client: DiscordClient?) {
        attachments = DiscordAttachment.attachmentsFromArray(messageObject.get("attachments", or: JSONArray()))
        author = DiscordUser(userObject: messageObject.get("author", or: [String: Any]()))
        channelId = Snowflake(messageObject["channel_id"] as? String) ?? 0
        content = messageObject.get("content", or: "")
        embeds = DiscordEmbed.embedsFromArray(messageObject.get("embeds", or: JSONArray()))
        id = Snowflake(messageObject["id"] as? String) ?? 0
        mentionEveryone = messageObject.get("mention_everyone", or: false)
        mentionRoles = messageObject.get("mention_roles", or: [String]()).flatMap(Snowflake.init)
        mentions = DiscordUser.usersFromArray(messageObject.get("mentions", or: JSONArray()))
        nonce = Snowflake(messageObject["nonce"] as? String) ?? 0
        pinned = messageObject.get("pinned", or: false)
        reactions = DiscordReaction.reactionsFromArray(messageObject.get("reactions", or: []))
        tts = messageObject.get("tts", or: false)
        editedTimestamp = DiscordDateFormatter.format(messageObject.get("edited_timestamp", or: "")) ?? Date()
        timestamp = DiscordDateFormatter.format(messageObject.get("timestamp", or: "")) ?? Date()
        files = []
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
    public init(content: String, embed: DiscordEmbed? = nil, file: DiscordFileUpload? = nil, tts: Bool = false) {
        self.content = content
        if let embed = embed {
            self.embeds = [embed]
        } else {
            self.embeds = []
        }
        if let file = file {
            self.files = [file]
        } else {
            self.files = []
        }
        self.tts = tts
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
        self.editedTimestamp = Date()
        self.timestamp = Date()
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
        if let file = files.first {
            var fields: [String: Any] = [
                "content": content,
                "tts": tts,
            ]

            if let embed = embeds.first {
                fields["embed"] = embed.json
            }

            let encoded = JSON.encodeJSON(fields) ?? ""

            return .right(createMultipartBody(fields: ["payload_json": encoded], file: file))
        } else {
            let messageObject: [String: Any] = [
                "content": content,
                "tts": tts,
                "embed": embeds.first?.json ?? [:]
            ]

            guard let contentData = JSON.encodeJSONData(messageObject) else { return .left(Data()) }

            return .left(contentData)
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
        id = Snowflake(attachmentObject.get("id", or: "")) ?? 0
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
public struct DiscordEmbed : JSONAble {
    var shouldIncludeNilsInJSON: Bool { return false }
    // MARK: Nested Types

    /// Represents an Embed's author.
    public struct Author : JSONAble {
        var shouldIncludeNilsInJSON: Bool { return false }
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
    public struct Field : JSONAble {
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
    public struct Footer : JSONAble {
        var shouldIncludeNilsInJSON: Bool { return false }
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
        public init(text: String?, iconUrl: URL?) {
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
    public struct Image : JSONAble {
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
    public struct Provider : JSONAble {
        var shouldIncludeNilsInJSON: Bool { return false }
        // MARK: Properties

        /// The name of this provider.
        public let name: String

        /// The url of this provider.
        public let url: URL?
    }

    /// Represents the thumbnail of an embed.
    public struct Thumbnail : JSONAble {
        var shouldIncludeNilsInJSON: Bool { return false }
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

    /// The title of this embed.
    public var title: String?

    /// The type of this embed.
    public let type: String

    /// The url of this embed.
    public var url: URL?

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
                thumbnail: Thumbnail? = nil,
                color: Int? = nil,
                footer: Footer? = nil,
                fields: [Field] = []) {
        self.title = title
        self.author = author
        self.description = description
        self.provider = nil
        self.thumbnail = thumbnail
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
        thumbnail = Thumbnail(thumbnailObject: embedObject.get("thumbnail", or: nil))
        title = embedObject.get("title", or: nil)
        type = embedObject.get("type", or: "")
        url = URL(string: embedObject.get("url", or: ""))
        image = Image(imageObject: embedObject.get("image", or: nil))
        fields = Field.fieldsFromArray(embedObject.get("fields", or: []))
        color = embedObject.get("color", or: nil)
        footer = Footer(footerObject: embedObject.get("footer", or: nil))
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
