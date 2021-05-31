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

/// Represents a presence.
public struct DiscordPresence {
    // MARK: Properties

    /// The snowflake of the guild this presence belongs on.
    public let guildId: GuildID

    /// The user associated with this presence.
    public let user: DiscordUser

    /// All of the user's current activies.
    public var activities: [DiscordActivity]

    /// This user's nick on this guild.
    public var nick: String?

    /// The roles?
    public var roles: [String]

    /// The status of this user.
    public var status: DiscordPresenceStatus

    init(presenceObject: [String: Any], guildId: GuildID) {
        self.guildId = guildId
        user = DiscordUser(userObject: presenceObject.get("user", or: [String: Any]()))
        activities = (presenceObject["activities"] as? [[String: Any]])?.map(DiscordActivity.init(gameObject:)).compactMap { $0 } ?? []
        nick = presenceObject["nick"] as? String
        status = DiscordPresenceStatus(rawValue: presenceObject.get("status", or: "")) ?? .offline
        roles = []
    }

    mutating func updatePresence(presenceObject: [String: Any]) {
        if let activities = presenceObject["activities"] as? [[String: Any]] {
            self.activities = activities.map(DiscordActivity.init(gameObject:)).compactMap { $0 }
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

/// Represents a presence status.
public enum DiscordPresenceStatus : String {
    // MARK: Cases

    /// User is idle.
    case idle = "idle"

    /// User is offline or hidden.
    case offline = "offline"

    /// User is online.
    case online = "online"

    /// This user won't receive notifications.
    case doNotDisturb = "dnd"
}

/// Represents an activity type.
public enum DiscordActivityType : Int, Encodable {
    // MARK: Cases

    /// A regular game.
    case game

    /// A stream.
    case stream

    /// Listening to something.
    case listening
}

/// Represents a game
public struct DiscordActivity : Encodable {
    // MARK: Properties

    /// The application id.
    public let applicationId: String?

    /// The assets for this activity.
    public let assets: DiscordActivityAssets?

    /// What the player is currently doing.
    public let details: String?

    /// The name of the game.
    public let name: String

    /// The party status.
    public let party: DiscordParty?

    /// The user's current party status
    public let state: String?

    /// Unix timestamps for the start and end of a game.
    public let timestamps: DiscordActivityTimestamps?

    /// The type of the game.
    public let type: DiscordActivityType

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
    public init(name: String, type: DiscordActivityType, url: String? = nil) {
        self.applicationId = nil
        self.assets = nil
        self.details = nil
        self.name = name
        self.party = nil
        self.state = nil
        self.timestamps = nil
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

        self.applicationId = game.get("application_id", as: String.self)
        self.assets = DiscordActivityAssets(assetsObj: game.get("assets", as: [String: Any].self))
        self.details = game.get("details", as: String.self)
        self.name = name
        self.party = DiscordParty(partyObj: game.get("party", as: [String: Any].self))
        self.state = game.get("state", as: String.self)
        self.timestamps = DiscordActivityTimestamps(timestampsObj: game.get("timestamps", as: [String: Int].self))
        self.type = DiscordActivityType(rawValue: game.get("type", or: 0)) ?? .game
        self.url = game["url"] as? String
    }

    /// Encodable requirement
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(name, forKey: .name)
        try container.encode(type, forKey: .type)

        if let url = self.url {
            try container.encode(url, forKey: .url)
        } else {
            try container.encodeNil(forKey: .url)
        }
    }

    private enum CodingKeys : CodingKey {
        case name, type, url
    }
}

/// Represents the start/end of a game.
public struct DiscordActivityTimestamps {
    // MARK: Properties

    /// The start.
    public let start: Int?

    /// The end.
    public let end: Int?

    init?(timestampsObj: [String: Int]?) {
        guard let timestampsObj = timestampsObj else { return nil }

        self.start = timestampsObj["start"]
        self.end = timestampsObj["end"]
    }
}

/// Represents the party status.
public struct DiscordParty {
    // MARK: Properties

    /// The id of the party.
    public let id: String

    /// The sizes of the party. Array of two elements, first is the current, second is the max size of the party.
    public let sizes: [Int]?

    init?(partyObj: [String: Any]?) {
        guard let partyObj = partyObj else { return nil }

        self.id = partyObj.get("id", or: "")
        self.sizes = partyObj.get("sizes", as: [Int].self)
    }
}

/// Represents presence assets.
public struct DiscordActivityAssets {
    // MARK: Properties

    /// The id of the large image.
    public let largeImage: String?

    /// The hover text for the large image.
    public let largeText: String?

    /// The id of the small image.
    public let smallImage: String?

    /// The hover text for the small image.
    public let smallText: String?

    init?(assetsObj: [String: Any]?) {
        guard let assetsObj = assetsObj else { return nil }

        self.largeImage = assetsObj.get("large_image", as: String.self)
        self.largeText = assetsObj.get("large_text", as: String.self)
        self.smallImage = assetsObj.get("small_image", as: String.self)
        self.smallText = assetsObj.get("small_text", as: String.self)
    }
}

/// Used to send updates to Discord about our presence.
public struct DiscordPresenceUpdate : Encodable {
    // MARK: Properties

    /// The time at which we went idle. Nil if not idle
    public var afkSince: Date?

    /// The game we are currently playing. Nil if not playing a game.
    public var game: DiscordActivity?

    /// The status for this update.
    public var status: DiscordPresenceStatus

    // MARK: Initializers

    ///
    /// Creates a new DiscordPresenceUpdate
    ///
    /// - parameter game: The game we are currently playing. Nil if not playing a game
    /// - parameter status: The current status
    /// - parameter afkSince: The time the user went afk. Nil if the user is not afk
    ///
    public init(game: DiscordActivity?, status: DiscordPresenceStatus = .online, afkSince: Date? = nil) {
        self.afkSince = afkSince
        self.game = game
        self.status = status
    }

    // Apparently Discord doesn't like it when we don't send null fields to gateway
    // Sadly, there's no way to tell swift's auto-generated encode to encode nil fields as null
    // So we need a manual encode function for it.
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        if let afkSince = afkSince {
            try container.encode(Int(afkSince.timeIntervalSince1970 * 1000), forKey: .since)
            try container.encode(true, forKey: .afk)
        } else {
            try container.encodeNil(forKey: .since)
            try container.encode(false, forKey: .afk)
        }
        if let game = game {
            let gameEncoder = container.superEncoder(forKey: .game)
            try game.encode(to: gameEncoder)
        } else {
            try container.encodeNil(forKey: .game)
        }
        try container.encode(status.rawValue, forKey: .status)
    }

    // For encoding
    enum CodingKeys : CodingKey {
        case since
        case game
        case status
        case afk
    }
}
