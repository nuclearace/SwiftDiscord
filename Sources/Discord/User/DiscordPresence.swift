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

/// Represents a presence.
public struct DiscordPresence: Codable, Identifiable, Hashable {
    public enum CodingKeys: String, CodingKey {
        case user
        case activities
        case nick
        case status
        case guildId
    }

    // MARK: Properties

    /// The user associated with this presence.
    public var user: DiscordUser

    /// All of the user's current activies.
    public var activities: [DiscordActivity]? = nil

    /// This user's nick on this guild.
    public var nick: String? = nil

    /// The roles?
    public var roles: [String]? = nil

    /// The status of this user.
    public var status: DiscordPresenceStatus? = nil

    /// The id of the guild.
    public var guildId: GuildID? = nil

    public var id: UserID { user.id }

    /// Merges another presence in.
    mutating func merge(update: DiscordPresence) {
        if let activities = update.activities {
            self.activities = activities
        }
        if let status = update.status {
            self.status = status
        }
    }
}

/// Represents a presence status.
public struct DiscordPresenceStatus: RawRepresentable, Codable, Hashable {
    public var rawValue: String

    /// User is idle.
    public static let idle = DiscordPresenceStatus(rawValue: "idle")
    /// User is offline or hidden.
    public static let offline = DiscordPresenceStatus(rawValue: "offline")
    /// User is online.
    public static let online = DiscordPresenceStatus(rawValue: "online")
    /// This user won't receive notifications.
    public static let doNotDisturb = DiscordPresenceStatus(rawValue: "dnd")

    public init(rawValue: String) {
        self.rawValue = rawValue
    }
}

/// Represents an activity type.
public struct DiscordActivityType: RawRepresentable, Codable, Hashable {
    public var rawValue: Int

    /// A regular game.
    /// TODO: Rename to `playing`
    public static let game = DiscordActivityType(rawValue: 0)

    /// A stream.
    public static let stream = DiscordActivityType(rawValue: 1)

    /// Listening to something.
    public static let listening = DiscordActivityType(rawValue: 2)

    /// Watching something
    public static let watching = DiscordActivityType(rawValue: 3)

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
}

/// Represents a game
public struct DiscordActivity: Codable, Hashable {
    // MARK: Properties

    /// The application id.
    public var applicationId: String?

    /// The assets for this activity.
    public var assets: DiscordActivityAssets?

    /// What the player is currently doing.
    public var details: String?

    /// The name of the game.
    public var name: String

    /// The party status.
    public var party: DiscordParty?

    /// The user's current party status
    public var state: String?

    /// Unix timestamps for the start and end of a game.
    public var timestamps: DiscordActivityTimestamps?

    /// The type of the game.
    public var type: DiscordActivityType

    /// The url of the stream, if a stream.
    public var url: String?

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

    private enum CodingKeys: String, CodingKey {
        case applicationId = "application_id"
        case assets
        case details
        case name
        case party
        case state
        case timestamps
        case type
        case url
    }
}

/// Represents the start/end of a game.
public struct DiscordActivityTimestamps: Codable, Hashable {
    // MARK: Properties

    /// The start.
    public var start: Int?

    /// The end.
    public var end: Int?
}

/// Represents the party status.
public struct DiscordParty: Codable, Identifiable, Hashable {
    // MARK: Properties

    /// The id of the party.
    public var id: String?

    /// The sizes of the party. Array of two elements, first is the current, second is the max size of the party.
    public var sizes: [Int]?
}

/// Represents presence assets.
public struct DiscordActivityAssets: Codable, Hashable {
    public enum CodingKeys: String, CodingKey {
        case largeImage = "large_image"
        case largeText = "large_text"
        case smallImage = "small_image"
        case smallText = "small_text"
    }

    // MARK: Properties

    /// The id of the large image.
    public var largeImage: String?

    /// The hover text for the large image.
    public var largeText: String?

    /// The id of the small image.
    public var smallImage: String?

    /// The hover text for the small image.
    public var smallText: String?
}

/// Used to send updates to Discord about our presence.
public struct DiscordPresenceUpdate: Encodable, Hashable {
    public enum CodingKeys: String, CodingKey {
        case since
        case activities
        case status
        case afk
    }

    // MARK: Properties

    /// The time at which we went idle. Nil if not idle
    public var afkSince: Date?

    /// The game we are currently playing. Nil if not playing a game.
    public var activities: [DiscordActivity]

    /// The status for this update.
    public var status: DiscordPresenceStatus

    // MARK: Initializers

    ///
    /// Creates a new DiscordPresenceUpdate
    ///
    /// - parameter activities: The games we are currently playing. Nil if not playing a game
    /// - parameter status: The current status
    /// - parameter afkSince: The time the user went afk. Nil if the user is not afk
    ///
    public init(
        activities: [DiscordActivity] = [],
        status: DiscordPresenceStatus = .online,
        afkSince: Date? = nil
    ) {
        self.afkSince = afkSince
        self.activities = activities
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
        try container.encode(activities, forKey: .activities)
        try container.encode(status, forKey: .status)
    }
}
