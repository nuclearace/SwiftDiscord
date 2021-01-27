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

/// Represents a user guild.
public struct DiscordUserGuild {
    // MARK: Properties

    /// The snowflake id of the guild.
    public let id: GuildID

    /// The name of the guild.
    public let name: String

    /// The base64 encoded icon of the guild.
    public let icon: String

    /// Whether the user is the owner of the guild.
    public let owner: Bool

    /// Bitwise of the user's enabled/disabled permissions.
    public let permissions: DiscordPermission

    init(userGuildObject: [String: Any]) {
        id = userGuildObject.getSnowflake()
        name = userGuildObject.get("name", or: "")
        icon = userGuildObject.get("icon", or: "")
        owner = userGuildObject.get("owner", or: false)
        permissions = DiscordPermission(rawValue: Int(userGuildObject.get("permissions", or: "0")) ?? 0)
    }

    static func userGuildsFromArray(_ guilds: [[String: Any]]) -> [GuildID: DiscordUserGuild] {
        var userGuildDictionary = [GuildID: DiscordUserGuild]()

        for guildObject in guilds {
            let guild = DiscordUserGuild(userGuildObject: guildObject)

            userGuildDictionary[guild.id] = guild
        }

        return userGuildDictionary
    }
}
