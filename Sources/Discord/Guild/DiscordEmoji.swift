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

import Logging

fileprivate let logger = Logger(label: "DiscordEmoji")

/// Represents an Emoji.
public struct DiscordEmoji: Identifiable, Codable, Hashable {
    public enum CodingKeys: String, CodingKey {
        case id
        case managed
        case animated
        case name
        case requireColons = "require_colons"
        case roles
    }

    // MARK: Properties

    /// The snowflake id of the emoji.  Nil if the emoji is a unicode emoji
    public let id: EmojiID?

    /// Whether this is a managed emoji.
    public let managed: Bool
    
    /// Whether this is an animated emoji.
    public let animated: Bool

    /// The name of the emoji or unicode representation if it's a unicode emoji.
    public let name: String

    /// Whether this emoji requires colons.
    public let requireColons: Bool

    /// An array of role snowflake ids this emoji is active for.
    public let roles: [RoleID]
}
