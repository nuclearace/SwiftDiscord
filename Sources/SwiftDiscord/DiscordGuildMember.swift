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

/// Represents a guild member.
public struct DiscordGuildMember {
    // MARK: Properties

    /// The id of the guild of this member.
    public let guildId: String

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
    public var roles: [String]

    /// The guild this member is on
    public internal(set) weak var guild: DiscordGuild?

    private var _deaf: Bool
    private var _mute: Bool
    private var _nick: String?

    init(guildMemberObject: [String: Any], guildId: String, guild: DiscordGuild? = nil) {
        self.guildId = guildId
        user = DiscordUser(userObject: guildMemberObject.get("user", or: [String: Any]()))
        _deaf = guildMemberObject.get("deaf", or: false)
        _mute = guildMemberObject.get("mute", or: false)
        _nick = guildMemberObject["nick"] as? String
        roles = guildMemberObject.get("roles", or: [String]())
        joinedAt = DiscordDateFormatter.format(guildMemberObject.get("joined_at", or: "")) ?? Date()
        self.guild = guild
    }

    static func guildMembersFromArray(_ guildMembersArray: [[String: Any]], withGuildId guildId: String,
                                      guild: DiscordGuild?)
            -> DiscordLazyDictionary<String, DiscordGuildMember> {
        var guildMembers = DiscordLazyDictionary<String, DiscordGuildMember>()

        for guildMember in guildMembersArray {
            guard let user = guildMember["user"] as? [String: Any], let id = user["id"] as? String else {
                fatalError("Couldn't extract userId")
            }

            guildMembers[lazy: id] = .lazy({[weak guild] in
                DiscordGuildMember(guildMemberObject: guildMember, guildId: guildId, guild: guild)
            })
        }

        return guildMembers
    }

    mutating func updateMember(_ updateObject: [String: Any]) -> DiscordGuildMember {
        if let roles = updateObject["roles"] as? [String] {
            self.roles = roles
        }

        _nick = updateObject["nick"] as? String

        return self
    }
}
