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

// TODO Meta object


/// Represents a generic invite object.
public struct DiscordInvite {
    // MARK: Properties

    /// The invite code.
    public let code: String

    /// The guild this invite is for.
    public let guild: DiscordInviteGuild

    /// The channel this invite is for.
    public let channel: DiscordInviteChannel

    init(inviteObject: [String: Any]) {
        code = inviteObject.get("code", or: "")
        guild = DiscordInviteGuild(inviteGuildObject: inviteObject.get("guild", or: [String: Any]()))
        channel = DiscordInviteChannel(inviteChannelObject: inviteObject.get("channel", or: [String: Any]()))
    }

    static func invitesFromArray(inviteArray: [[String: Any]]) -> [DiscordInvite] {
        return inviteArray.map(DiscordInvite.init)
    }
}

/// Represents an invite to a guild.
public struct DiscordInviteGuild {
    // MARK: Properties

    /// The snowflake id of the guild this invite is for.
    public let id: GuildID

    /// The name of the guild this invite is for.
    public let name: String

    /// The splash of this guild.
    public let splashHash: String

    init(inviteGuildObject: [String: Any]) {
        id = inviteGuildObject.getSnowflake()
        name = inviteGuildObject.get("name", or: "")
        splashHash = inviteGuildObject.get("splash_hash", or: "")
    }
}

/// Represents an invite to a channel.
public struct DiscordInviteChannel {
    // MARK: Properties

    /// The snowflake id of the channel this invite is for.
    public let id: ChannelID

    /// The name of the channel this invite is for.
    public let name: String

    /// The type of channel this invite is for.
    public let type: DiscordChannelType

    init(inviteChannelObject: [String: Any]) {
        id = inviteChannelObject.getSnowflake()
        name = inviteChannelObject.get("name", or: "")
        type = DiscordChannelType(rawValue: inviteChannelObject.get("type", or: 0)) ?? .text
    }
}
