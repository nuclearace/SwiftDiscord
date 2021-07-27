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
public struct DiscordPresence: Codable {
    public enum CodingKeys: String, CodingKey {
        case user
        case activities
        case nick
        case status
    }

    // MARK: Properties

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
}

/// Represents a presence status.
public enum DiscordPresenceStatus: String, Codable {
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
public enum DiscordActivityType: Int, Codable {
    // MARK: Cases

    /// A regular game.
    /// TODO: Rename to `playing`
    case game = 0

    /// A stream.
    case stream = 1

    /// Listening to something.
    case listening = 2

    /// Watching something
    case watching = 3
}

/// Represents a game
public struct DiscordActivity: Codable {
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

    private enum CodingKeys: CodingKey {
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
public struct DiscordActivityTimestamps: Codable {
    // MARK: Properties

    /// The start.
    public let start: Int?

    /// The end.
    public let end: Int?
}

/// Represents the party status.
public struct DiscordParty: Codable, Identifiable {
    // MARK: Properties

    /// The id of the party.
    public let id: String

    /// The sizes of the party. Array of two elements, first is the current, second is the max size of the party.
    public let sizes: [Int]?
}

/// Represents presence assets.
public struct DiscordActivityAssets: Codable {
    public enum CodingKeys: String, CodingKey {
        case largeImage = "large_image"
        case smallImage = "small_image"
        case smallText = "small_text"
    }

    // MARK: Properties

    /// The id of the large image.
    public let largeImage: String?

    /// The hover text for the large image.
    public let largeText: String?

    /// The id of the small image.
    public let smallImage: String?

    /// The hover text for the small image.
    public let smallText: String?
}

/// Used to send updates to Discord about our presence.
public struct DiscordPresenceUpdate: Encodable {
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

    public enum CodingKeys: CodingKey {
        case since
        case game
        case status
        case afk
    }
}
