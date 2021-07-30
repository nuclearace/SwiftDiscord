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

/// The most basic form of event sent and received via Discord's gateway.
public enum DiscordGatewayPayload: Codable {
    // MARK: Commands (Send)

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

    // MARK: Events (Receive)

    /// An event was dispatched (receive).
    case dispatch(DiscordDispatchEvent)
    /// We should attempt to reconnect and resume immediately.
    case reconnect
    /// The session has been invalidated. We should reconnect and identify/
    /// resume accordinly.
    case invalidSession
    /// Sent immediately after connecting, contains the `heartbeat_interval`.
    case hello
    /// Sent in response to receiving a heartbeat to acknowledge that it has
    /// been received.
    case heartbeatAck
}

/// Represents a regular gateway opcode
public enum DiscordGatewayPayloadOpcode: Int, Codable {
    /// Dispatch.
    case dispatch = 0
    /// Heartbeat.
    case heartbeat = 1
    /// Identify.
    case identify = 2
    /// Status Update.
    case statusUpdate = 3
    /// Voice Status Update.
    case voiceStatusUpdate = 4
    /// Voice Server Ping.
    case voiceServerPing = 5
    /// Resume.
    case resume = 6
    /// Reconnect.
    case reconnect = 7
    /// Request Guild Members.
    case requestGuildMembers = 8
    /// Invalid Session.
    case invalidSession = 9
    /// Hello.
    case hello = 10
    /// HeartbeatAck
    case heartbeatAck = 11
}

/// Used to maintain an active gateway connection. Must be sent
/// every `heartbeat_interval` ms after the hello.
public struct DiscordGatewayHeartbeat: RawRepresentable, Codable {
    /// The last sequence number received by the client.
    public var rawValue: Int

    public init(rawValue: Int) {
        self.rawValue = rawValue
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
    public var intents: DiscordIntent
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
