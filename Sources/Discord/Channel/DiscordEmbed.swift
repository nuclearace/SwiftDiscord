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

/// Represents an embeded entity.
public struct DiscordEmbed: Codable, Hashable {
    // MARK: Nested Types

    /// Represents an Embed's author.
    public struct Author: Codable, Hashable {
        private enum CodingKeys: String, CodingKey {
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
    public struct Field: Codable, Hashable {
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
    public struct Footer: Codable, Hashable {
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
    public struct Image: Codable, Hashable {
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
    public struct Provider: Codable, Hashable {
        // MARK: Properties

        /// The name of this provider.
        public let name: String

        /// The url of this provider.
        public let url: URL?
    }

    /// Represents the thumbnail of an embed.
    public struct Thumbnail: Codable, Hashable {
        private enum CodingKeys: String, CodingKey {
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
    public struct Video: Codable, Hashable {
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
    public var fields: [Field]?

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
                fields: [Field]? = nil) {
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
}
