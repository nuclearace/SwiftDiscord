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

import Foundation

/// An interactive part of a message.
public struct DiscordMessageComponent: Codable, Hashable {
    public enum CodingKeys: String, CodingKey {
        case type
        case components
        case style
        case label
        case emoji
        case customId = "custom_id"
        case url
        case disabled
        case options
        case placeholder
        case minValues = "min_values"
        case maxValues = "max_values"
    }

    /// The type of the component.
    public var type: DiscordMessageComponentType
    /// Sub-components. Only valid for action rows.
    public var components: [DiscordMessageComponent]? = nil
    /// One of a few button styles. Only valid for buttons.
    public var style: DiscordMessageComponentButtonStyle? = nil
    /// Label that appears on a button. Only valid for buttons.
    public var label: String? = nil
    /// Emoji that appears on the button. Only valid for buttons.
    public var emoji: DiscordMessageComponentEmoji? = nil
    /// A developer-defined id for the button, max 100 chars.
    /// Only valid for buttons and select menus.
    public var customId: String? = nil
    /// A URL for link-style buttons. Only valid for buttons.
    public var url: URL? = nil
    /// Whether the button is disabled. False by default.
    /// Only valid for buttons and select menus.
    public var disabled: Bool? = nil
    /// The choices in the select, max 25.
    /// Only valid for select menus.
    public var options: [DiscordMessageComponentSelectOption]? = nil
    /// Custom placeholder text if nothing is selected,
    /// max 100 characters.
    public var placeholder: String? = nil
    /// The minimum number of items that must be chosen, default 1,
    /// min 0, max 25
    public var minValues: Int? = nil
    /// The maximum number of items that can be chosen, default 1,
    /// min 0, max 25
    public var maxValues: Int? = nil

    /// Creates a new button component.
    /// Must be inside an action row.
    public static func button(
        style: DiscordMessageComponentButtonStyle? = nil,
        label: String? = nil,
        emoji: DiscordMessageComponentEmoji? = nil,
        url: URL? = nil,
        customId: String,
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

    /// Creates a new select menu component.
    /// Must be inside an action row, also an action menu can only
    /// contain one select menu.
    public static func selectMenu(
        options: [DiscordMessageComponentSelectOption] = [],
        placeholder: String? = nil,
        minValues: Int? = nil,
        maxValues: Int? = nil,
        customId: String,
        disabled: Bool? = nil
    ) -> DiscordMessageComponent {
        DiscordMessageComponent(
            type: .selectMenu,
            customId: customId,
            disabled: disabled,
            options: options,
            placeholder: placeholder,
            minValues: minValues,
            maxValues: maxValues
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
    public static let selectMenu = DiscordMessageComponentType(rawValue: 3)

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

/// A visual button component style.
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

/// A choice in a select menu.
public struct DiscordMessageComponentSelectOption: Codable, Hashable {
    /// The user-facing label of the option, max 25 chars
    public var label: String
    /// The dev-defined value of the option, max 100 chars
    public var value: String
    /// An additional description of the option, max 50 chars
    public var description: String?
    /// `id`, `name` and `animated`
    public var emoji: DiscordEmoji?
    /// Whether this option should be selected by default
    public var `default`: Bool?

    public init(
        label: String,
        value: String,
        description: String? = nil,
        emoji: DiscordEmoji? = nil,
        default: Bool? = nil
    ) {
        self.label = label
        self.value = value
        self.description = description
        self.emoji = emoji
        self.default = `default`
    }
}
