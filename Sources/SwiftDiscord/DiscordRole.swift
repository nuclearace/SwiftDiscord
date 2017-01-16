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

/// Represents a Discord role.
public struct DiscordRole : JSONAble {
    // MARK: Properties

    /// The snowflake id of the role.
    public let id: String

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
    ///
    /// *Bit field*
    public var permissions: Int

    /// The position of this role.
    public var position: Int

    init(roleObject: [String: Any]) {
        color = roleObject.get("color", or: 0)
        hoist = roleObject.get("hoist", or: false)
        id = roleObject.get("id", or: "")
        managed = roleObject.get("managed", or: false)
        mentionable = roleObject.get("mentionable", or: false)
        name = roleObject.get("name", or: "")
        permissions = roleObject.get("permissions", or: 0)
        position = roleObject.get("position", or: 0)
    }

    static func rolesFromArray(_ rolesArray: [[String: Any]]) -> [String: DiscordRole] {
        var roles = [String: DiscordRole]()

        for role in rolesArray {
            let role = DiscordRole(roleObject: role)

            roles[role.id] = role
        }

        return roles
    }
}
