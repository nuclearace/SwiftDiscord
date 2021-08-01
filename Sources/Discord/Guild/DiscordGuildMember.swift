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
import Logging

fileprivate let logger = Logger(label: "DiscordGuildMember")

/// Represents a guild member.
public struct DiscordGuildMember: Codable, Identifiable, Hashable {
    public enum CodingKeys: String, CodingKey {
        case guildId = "guild_id"
        case joinedAt = "joined_at"
        case user
        case deaf
        case mute
        case roleIds = "roles"
    }

    // MARK: Properties

    /// The id of the guild of this member.
    public var guildId: GuildID

    /// The date this member joined the guild.
    public var joinedAt: Date

    /// The user object for this member.
    public var user: DiscordUser

    /// Whether this member has been deafened.
    public var deaf: Bool

    /// Whether this member is muted.
    public var mute: Bool

    /// This member's nickname, if they have one.
    public var nick: String?

    /// An array of role snowflake ids that this user has.
    public var roleIds: [RoleID]

    public var id: UserID { user.id }

    init(guildId: GuildID, user: DiscordUser, deaf: Bool, mute: Bool, nick: String?, roleIds: [RoleID], joinedAt: Date) {
        self.user = user
        self.deaf = deaf
        self.mute = mute
        self.nick = nick
        self.roleIds = roleIds
        self.joinedAt = joinedAt
        self.guildId = guildId
    }

    mutating func updateMember(_ update: DiscordGuildMemberUpdate) {
        self.roleIds = update.roleIds
        self.nick = update.nick
    }
}

/// A guild member update event
public struct DiscordGuildMemberUpdate: Codable {
    public enum CodingKeys: String, CodingKey {
        case roleIds = "roles"
        case nick
    }

    /// The user role IDs
    public var roleIds: [RoleID]

    /// Nickname of the user in the guild
    public var nick: String?
}
