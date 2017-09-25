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

/// Represents a game type.
public enum DiscordGameType : Int, Encodable {
    /// A regular game.
    case game = 0

    /// A stream.
    case stream = 1
}

/// Represents a game
public struct DiscordGame : Encodable {
    // MARK: Properties

    /// The name of the game.
    public let name: String

    /// The type of the game.
    public let type: DiscordGameType

    /// The url of the stream, if a stream.
    public let url: String?

    // MARK: Initializers

    ///
    /// Creates a new DiscordGame.
    ///
    /// - parameter name: The name of the game
    /// - parameter type: The type of the game
    /// - parameter url: The url of the stream, if a stream
    ///
    public init(name: String, type: DiscordGameType, url: String? = nil) {
        self.name = name
        self.type = type
        self.url = url
    }


    ///
    /// Creates a new DiscordGame from a json object.
    ///
    /// Can fail if no game object was given.
    ///
    /// - parameter gameObject: The json game
    ///
    public init?(gameObject: [String: Any]?) {
        guard let game = gameObject else { return nil }
        guard let name = game["name"] as? String else { return nil }

        self.name = name
        self.type = DiscordGameType(rawValue: game.get("type", or: 0)) ?? .game
        self.url = game["url"] as? String
    }
}

/// Represents a presence status.
public enum DiscordPresenceStatus : String {
    /// User is idle.
    case idle = "idle"

    /// User is offline or hidden.
    case offline = "offline"

    /// User is online.
    case online = "online"

    /// This user won't receive notifications.
    case doNotDisturb = "dnd"
}

/// Represents a presence.
public struct DiscordPresence {
    // MARK: Properties

    /// The snowflake of the guild this presence belongs on.
    public let guildId: GuildID

    /// The user associated with this presence.
    public let user: DiscordUser

    /// The game this user is playing, if they are playing a game.
    public var game: DiscordGame?

    /// This user's nick on this guild.
    public var nick: String?

    /// The roles?
    public var roles: [String]

    /// The status of this user.
    public var status: DiscordPresenceStatus

    init(presenceObject: [String: Any], guildId: GuildID) {
        self.guildId = guildId
        user = DiscordUser(userObject: presenceObject.get("user", or: [String: Any]()))
        game = DiscordGame(gameObject: presenceObject["game"] as? [String: Any])
        nick = presenceObject["nick"] as? String
        status = DiscordPresenceStatus(rawValue: presenceObject.get("status", or: "")) ?? .offline
        roles = []
    }

    mutating func updatePresence(presenceObject: [String: Any]) {
        if let game = presenceObject["game"] as? [String: Any] {
            self.game = DiscordGame(gameObject: game)
        } else {
            game = nil
        }

        if let nick = presenceObject["nick"] as? String {
            self.nick = nick
        }

        if let roles = presenceObject["roles"] as? [String] {
            self.roles = roles
        }

        if let status = presenceObject["status"] as? String {
            self.status = DiscordPresenceStatus(rawValue: status) ?? .offline
        }
    }

    static func presencesFromArray(_ presencesArray: [[String: Any]], guildId: GuildID)
            -> DiscordLazyDictionary<UserID, DiscordPresence> {
        var presences = DiscordLazyDictionary<UserID, DiscordPresence>()

        for presence in presencesArray {
            guard let user = presence["user"] as? [String: Any], let id = Snowflake(user["id"] as? String) else {
                fatalError("Couldn't extract userId")
            }

            presences[lazy: id] = .lazy({ DiscordPresence(presenceObject: presence, guildId: guildId) })
        }

        return presences
    }
}


/// Used to send updates to Discord about our presence.
public struct DiscordPresenceUpdate : Encodable {
    // MARK: Properties

    /// The time we've been idle for. Nil if not idle
    public let since: Int?

    /// The game we are currently playing. Nil if not playing a game.
    public let game: DiscordGame?

    // MARK: Initializers

    ///
    /// Creates a new DiscordPresenceUpdate
    ///
    /// - parameter since: The time we've been idle for. Nil if not idle
    /// - parameter game: The game we are currently playing. Nil if not playing a game.
    ///
    public init(since: Int?, game: DiscordGame?) {
        self.since = since
        self.game = game
    }
}
