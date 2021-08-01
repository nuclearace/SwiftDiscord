// The MIT License (MIT)
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

/// An interactive part of a message.
public struct DiscordMessageComponent: Codable, Hashable {
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
    public var type: DiscordMessageComponentType
    /// Sub-components. Only valid for action rows.
    public var components: [DiscordMessageComponent]?
    /// One of a few button styles. Only valid for buttons.
    public var style: DiscordMessageComponentButtonStyle?
    /// Label that appears on a button. Only valid for buttons.
    public var label: String?
    /// Emoji that appears on the button. Only valid for buttons.
    public var emoji: DiscordMessageComponentEmoji?
    /// A developer-defined id for the button, max 100 chars. Only valid for buttons.
    public var customId: String?
    /// A URL for link-style buttons. Only valid for buttons.
    public var url: URL?
    /// Whether the button is disabled. False by default. Only valid for buttons.
    public var disabled: Bool?

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

public struct DiscordMessageComponentType: RawRepresentable, Hashable, Codable {
    public var rawValue: Int

    public static let actionRow = DiscordMessageComponentType(rawValue: 1)
    public static let button = DiscordMessageComponentType(rawValue: 2)

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
}

/// A partial emoji for use in message components.
public struct DiscordMessageComponentEmoji: Codable, Identifiable, Hashable {
    public var id: EmojiID?
    public var name: String?
    public var animated: Bool?

    public init(id: EmojiID? = nil, name: String? = nil, animated: Bool? = nil) {
        self.id = id
        self.name = name
        self.animated = animated
    }
}

public struct DiscordMessageComponentButtonStyle: RawRepresentable, Hashable, Codable {
    public var rawValue: Int

    public static let primary = DiscordMessageComponentButtonStyle(rawValue: 1)
    public static let secondary = DiscordMessageComponentButtonStyle(rawValue: 2)
    public static let success = DiscordMessageComponentButtonStyle(rawValue: 3)
    public static let danger = DiscordMessageComponentButtonStyle(rawValue: 4)
    public static let link = DiscordMessageComponentButtonStyle(rawValue: 5)

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
}
