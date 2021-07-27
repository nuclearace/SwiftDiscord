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
public struct DiscordGuildMember: Codable {
    public enum CodingKeys: String, CodingKey {
        case guildId = "guild_id"
        case joinedAt = "joined_at"
        case user
        case deaf
        case mute
        case roleIds = "role_ids"
    }

    // MARK: Properties

    /// The id of the guild of this member.
    public let guildId: GuildID

    /// The date this member joined the guild.
    public let joinedAt: Date

    /// The user object for this member.
    public let user: DiscordUser

    /// Whether this member has been deafened.
    public let deaf: Bool

    /// Whether this member is muted.
    public var mute: Bool

    /// This member's nickname, if they have one.
    public var nick: String?

    /// An array of role snowflake ids that this user has.
    public var roleIds: [RoleID]

    init(guildId: GuildID, user: DiscordUser, deaf: Bool, mute: Bool, nick: String?, roleIds: [RoleID], joinedAt: Date,
         guild: DiscordGuild? = nil) {
        self.user = user
        self._deaf = deaf
        self._mute = mute
        self._nick = nick
        self.roleIds = roleIds
        self.joinedAt = joinedAt
        self.guild = guild
        self.guildId = guildId
    }

    static func guildMembersFromArray(_ guildMembersArray: [[String: Any]], withGuildId guildId: GuildID,
                                      guild: DiscordGuild?) -> DiscordLazyDictionary<UserID, DiscordGuildMember> {
        var guildMembers = DiscordLazyDictionary<UserID, DiscordGuildMember>()

        for guildMember in guildMembersArray {
            guard let user = guildMember["user"] as? [String: Any], let id = Snowflake(user["id"] as? String) else {
                logger.error("Couldn't extract userId from user JSON")
                continue
            }

            guildMembers[lazy: id] = .lazy({[weak guild] in
                DiscordGuildMember(guildMemberObject: guildMember, guildId: guildId, guild: guild)
            })
        }

        return guildMembers
    }

    ///
    /// Searches this member for a role with a name that matches.
    ///
    /// - parameter role: The role's name to look for.
    /// - return: Whether or not they have this role.
    ///
    public func hasRole(_ role: String) -> Bool {
        guard let roles = self.roles else { return false }

        return roles.contains(where: { $0.name == role })
    }

    mutating func updateMember(_ updateObject: [String: Any]) -> DiscordGuildMember {
        if let roles = updateObject["roles"] as? [String] {
            self.roleIds = roles.compactMap(Snowflake.init)
        }

        _nick = updateObject["nick"] as? String

        return self
    }
}
