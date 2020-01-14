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
import Logging

fileprivate let logger = Logger(label: "DiscordGuildMember")

/// Represents a guild member.
public struct DiscordGuildMember {
    // MARK: Properties

    /// The id of the guild of this member.
    public let guildId: GuildID

    /// The date this member joined the guild.
    public let joinedAt: Date

    /// The user object for this member.
    public let user: DiscordUser

    /// Whether this member has been deafened.
    /// Changing this will cause the client to attempt to change the deafen status on Discord.
    public var deaf: Bool {
        get {
            return _deaf
        }

        set {
            guild?.modifyMember(self, options: [.deaf(newValue)])
        }
    }

    /// If this member has a guild object attached, this returns the `DiscordRoles` for the member.
    /// If a guild is unavailable, you can call `roles(for:)` on this member's guild directly.
    /// - returns: An Array of `DiscordRole` or nil if there is no guild attached to this member.
    public var roles: [DiscordRole]? {
        // TODO cache this
        guard let guild = self.guild else { return nil }

        return guild.roles(for: self)
    }

    /// Whether this member is muted.
    /// Changing this will cause the client to attempt to change the deafen status on Discord.
    public var mute: Bool {
        get {
            return _mute
        }

        set {
            guild?.modifyMember(self, options: [.mute(newValue)])
        }
    }

    /// This member's nickname, if they have one.
    /// Changing this value will cause the client to attempt to change the nick on Discord.
    public var nick: String? {
        get {
            return _nick
        }

        set {
            guild?.modifyMember(self, options: [.nick(newValue)])
        }
    }

    /// An array of role snowflake ids that this user has.
    public var roleIds: [RoleID]

    /// The guild this member is on
    public internal(set) weak var guild: DiscordGuild?

    private var _deaf: Bool
    private var _mute: Bool
    private var _nick: String?

    init(guildMemberObject: [String: Any], guildId: GuildID, guild: DiscordGuild? = nil) {
        self.guildId = guildId
        user = DiscordUser(userObject: guildMemberObject.get("user", or: [String: Any]()))
        _deaf = guildMemberObject.get("deaf", or: false)
        _mute = guildMemberObject.get("mute", or: false)
        _nick = guildMemberObject["nick"] as? String
        roleIds = (guildMemberObject["roles"] as? [String])?.compactMap(Snowflake.init) ?? []
        joinedAt = DiscordDateFormatter.format(guildMemberObject.get("joined_at", or: "")) ?? Date()
        self.guild = guild
    }

    init(guildId: GuildID, user: DiscordUser, deaf: Bool, mute: Bool, nick: String?, roles: [RoleID], joinedAt: Date,
         guild: DiscordGuild? = nil) {
        self.user = user
        self._deaf = deaf
        self._mute = mute
        self._nick = nick
        self.roleIds = roles
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
