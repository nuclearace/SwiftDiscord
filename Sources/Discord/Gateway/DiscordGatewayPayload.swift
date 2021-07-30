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

public enum DiscordGatewayPayload: Codable {
    /// An event was dispatched (receive).
    /// Receive.
    case dispatch(DiscordDispatchEvent)
    /// Fired periodically by the client to keep the connection alive.
    /// Send/Receive.
    case heartbeat(DiscordHeartbeat)
    /// Starts a new session during the initial handshake.
    /// Send.
    case identify(DiscordIdentify)
    /// Updates the clients presence.
    /// Send.
    case presenceUpdate
    /// Resumes a previous session that was disconnected.
    /// Send.
    case resume(DiscordResume)
    /// You should attempt to reconnect and resume immediately.
    /// Receive.
    case reconnect
    /// Request information about offline guild members in a large guild.
    /// Send.
    case requestGuildMembers
    /// The session has been invalidated. You should reconnect and identify/
    /// resume accordinly.
    /// Receive.
    case invalidSession
    /// Sent immediately after connecting, contains the `heartbeat_interval`.
    /// Receive.
    case hello
    /// Sent in response to receiving a heartbeat to acknowledge that it has
    /// been received.
    /// Receive.
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

public struct DiscordHeartbeat: RawRepresentable, Codable {
    /// The last sequence number received by the client.
    public var rawValue: Int

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
}

/// An event for identifying itself to the gateway.
public struct DiscordIdentify: Codable {
    /// The token to use.
    public var token: DiscordToken
    /// The intents to provide.
    public var intents: DiscordIntent
    /// Information about the client.
    public var properties: [String: String]
}

/// An event for 'resuming' a connection, replaying lost events.
public struct DiscordResume: Codable {
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
