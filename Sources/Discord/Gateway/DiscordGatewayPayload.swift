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

/// A gateway payload to be sent.
public enum DiscordGatewayCommand: Encodable {
    /// Starts a new session during the initial handshake.
    case identify(DiscordGatewayIdentify)
    /// Fired periodically by the client to keep the connection alive.
    case heartbeat(DiscordGatewayHeartbeat)
    /// Resumes a previous session that was disconnected.
    case resume(DiscordGatewayResume)
    /// Updates the clients presence.
    case presenceUpdate(DiscordGatewayPresenceUpdate)
    /// Request information about offline guild members in a large guild.
    case requestGuildMembers(DiscordGatewayRequestGuildMembers)

    public enum CodingKeys: String, CodingKey {
        case opcode = "op"
        case data = "d"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .identify(let identify): 
            try container.encode(DiscordGatewayOpcode.identify, forKey: .opcode)
            try container.encode(identify, forKey: .data)
        case .heartbeat(let heartbeat):
            try container.encode(DiscordGatewayOpcode.heartbeat, forKey: .opcode)
            try container.encode(heartbeat, forKey: .data)
        case .resume(let resume):
            try container.encode(DiscordGatewayOpcode.resume, forKey: .opcode)
            try container.encode(resume, forKey: .data)
        case .presenceUpdate(let update):
            try container.encode(DiscordGatewayOpcode.presenceUpdate, forKey: .opcode)
            try container.encode(update, forKey: .data)
        case .requestGuildMembers(let request):
            try container.encode(DiscordGatewayOpcode.requestGuildMembers, forKey: .opcode)
            try container.encode(request, forKey: .data)
        }
    }
}

/// A gateway payload to be received.
public enum DiscordGatewayEvent: Decodable {
    /// An event was dispatched (receive).
    case dispatch(DiscordGatewayDispatch)
    /// We should attempt to reconnect and resume immediately.
    case reconnect
    /// The session has been invalidated. We should reconnect and identify/
    /// resume accordinly.
    case invalidSession(DiscordGatewayInvalidSession)
    /// Sent immediately after connecting, contains the `heartbeat_interval`.
    case hello(DiscordGatewayHello)
    /// Sent in response to receiving a heartbeat to acknowledge that it has
    /// been received.
    case heartbeatAck

    public enum CodingKeys: String, CodingKey {
        case opcode = "op"
        case data = "d"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let opcode = try container.decode(DiscordGatewayOpcode.self, forKey: .opcode)
        switch opcode {
        case .dispatch: self = .dispatch(try DiscordGatewayDispatch(from: decoder))
        case .reconnect: self = .reconnect
        case .invalidSession: self = .invalidSession(try container.decode(DiscordGatewayInvalidSession.self, forKey: .data))
        case .hello: self = .hello(try container.decode(DiscordGatewayHello.self, forKey: .data))
        case .heartbeatAck: self = .heartbeatAck
        default: throw DiscordGatewayEventError.unrecognizedOpcode(opcode)
        }
    }
}

public enum DiscordGatewayEventError: Error {
    case unrecognizedOpcode(DiscordGatewayOpcode)
}

/// Represents a regular gateway opcode.
public struct DiscordGatewayOpcode: RawRepresentable, Codable, Hashable {
    public var rawValue: Int

    public static let dispatch = DiscordGatewayOpcode(rawValue: 0)
    public static let heartbeat = DiscordGatewayOpcode(rawValue: 1)
    public static let identify = DiscordGatewayOpcode(rawValue: 2)
    public static let presenceUpdate = DiscordGatewayOpcode(rawValue: 3)
    public static let voiceStatusUpdate = DiscordGatewayOpcode(rawValue: 4)
    public static let voiceServerPing = DiscordGatewayOpcode(rawValue: 5)
    public static let resume = DiscordGatewayOpcode(rawValue: 6)
    public static let reconnect = DiscordGatewayOpcode(rawValue: 7)
    public static let requestGuildMembers = DiscordGatewayOpcode(rawValue: 8)
    public static let invalidSession = DiscordGatewayOpcode(rawValue: 9)
    public static let hello = DiscordGatewayOpcode(rawValue: 10)
    public static let heartbeatAck = DiscordGatewayOpcode(rawValue: 11)

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
}

/// Used to maintain an active gateway connection. Must be sent
/// every `heartbeat_interval` ms after the hello.
public struct DiscordGatewayHeartbeat: RawRepresentable, Codable {
    /// The last sequence number received by the client.
    public var lastSequenceNumber: Int

    public var rawValue: Int {
        get { lastSequenceNumber }
        set { lastSequenceNumber = newValue }
    }

    public init(lastSequenceNumber: Int) {
        self.lastSequenceNumber = lastSequenceNumber
    }

    public init(rawValue: Int) {
        self.init(lastSequenceNumber: rawValue)
    }
}

#if os(Linux)
private let currentOS = "Linux"
#elseif os(macOS)
private let currentOS = "macOS"
#elseif os(Windows)
private let currentOS = "Windows"
#else
private let currentOS = "Other"
#endif

/// An event for identifying itself to the gateway.
public struct DiscordGatewayIdentify: Codable {
    public enum CodingKeys: String, CodingKey {
        case token
        case intents
        case properties
        case compress
        case largeThreshold = "large_threshold"
        case shard
        case presence
    }

    /// The token to use.
    public var token: DiscordToken
    /// The gateway intents we wish to receive.
    public var intents: DiscordGatewayIntents
    /// Connection properties.
    public var properties: Properties
    /// Whether this connection supports compression of packets.
    public var compress: Bool? = false
    /// Value between 50 and 250, total number of members where the
    /// gateway will stop sending offline members in the guild member
    /// list.
    public var largeThreshold: Int? = 50
    /// Array of two integers (shard_id, num_shards)
    public var shard: [Int]? = nil
    /// A presence update.
    public var presence: DiscordGatewayPresenceUpdate? = nil

    /// Connection properties.
    public struct Properties: Codable {
        /// Our operating system.
        public var os: String = currentOS
        /// Our library name.
        public var browser: String = "swift-discord"
        /// Our library name.
        public var device: String = "swift-discord"
    }
}

/// An event for 'resuming' a connection, replaying lost events.
public struct DiscordGatewayResume: Codable {
    public enum CodingKeys: String, CodingKey {
        case token
        case sessionId = "session_id"
        case sequenceNumber = "seq"
    }

    /// The token to use.
    public var token: DiscordToken
    /// The session id stored from ready.
    public var sessionId: String
    /// The sequence number of the last event received.
    public var sequenceNumber: Int
}

/// Used to request all members for a guild or a list of guilds.
public struct DiscordGatewayRequestGuildMembers: Codable {
    /// The id of the guild to get members for.
    public var guildId: GuildID
    /// String that username starts with (allows empty string for all).
    /// Either `query` or `userIds` is needed.
    public var query: String? = nil
    /// Used to specify which users we wish to fetch.
    /// Either `query` or `userIds` is needed.
    public var userIds: [UserID]? = nil
    /// Maximum number of members to send matching the `query`.
    /// Limit of 0 may be used to return all members.
    public var limit: Int = 0
    /// Used to specify if we want the presenced of the matched members.
    public var presences: Bool? = false
    /// Nonce to identify the guild members chunk response.
    public var nonce: String? = nil
}

/// Sent by the client to indicate a presence update.
public struct DiscordGatewayPresenceUpdate: Codable {
    /// Unix time in ms of when the client went idle, or
    /// null if the client is not idle.
    public var since: Int? = nil
    /// The user's activities.
    public var activities: [DiscordActivity]
    /// The user's new status.
    public var status: DiscordPresenceStatus
    /// Whether or not the client is afk.
    public var afk: Bool
}

/// A dispatch event.
public struct DiscordGatewayDispatch: Decodable {
    public enum CodingKeys: String, CodingKey {
        case sequenceNumber = "seq"
    }

    /// The sequence number.
    public var sequenceNumber: Int
    /// The event type and data.
    public var event: DiscordDispatchEvent

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        sequenceNumber = try container.decode(Int.self, forKey: .sequenceNumber)
        event = try DiscordDispatchEvent(from: decoder)
    }
}

/// Indicates one of three situations:
///   - The gateway could not initialize a session after opcode 2 identify
///   - The gateway could not resume a previous session after opcode 6 resume
///   - The gateway has invalidated an active session and is requesting client action
public struct DiscordGatewayInvalidSession: RawRepresentable, Codable {
    /// Whether the session is resumsable.
    public var isResumable: Bool

    public var rawValue: Bool {
        get { isResumable }
        set { isResumable = newValue }
    }

    public init(isResumable: Bool) {
        self.isResumable = isResumable
    }

    public init(rawValue: Bool) {
        self.init(isResumable: rawValue)
    }
}

/// Defines the heartbeat interval for the client.
public struct DiscordGatewayHello: Codable {
    public enum CodingKeys: String, CodingKey {
        case heartbeatInterval = "heartbeat_interval"
    }

    /// The heartbeat interval in milliseconds that
    /// we (the client) should heartbeat to.
    public var heartbeatInterval: Int
}
