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

/// Represents a Discord role.
public struct DiscordRole: Codable, Identifiable, Equatable {
    // MARK: Properties

    /// The snowflake id of the role.
    public let id: RoleID

    /// The display color of this role.
    public var color: Int

    /// Whether this role should be hoisted.
    public var hoist: Bool

    /// Whether this role is managed.
    public var managed: Bool

    /// Whether this role is mentionable.
    public var mentionable: Bool

    /// The name of this role.
    public var name: String

    /// The permissions this role has.
    public var permissions: DiscordPermissions

    /// The position of this role.
    public var position: Int

    ///
    /// Whether two roles are the same.
    ///
    public static func ==(lhs: DiscordRole, rhs: DiscordRole) -> Bool {
        return lhs.id == rhs.id
    }
}
