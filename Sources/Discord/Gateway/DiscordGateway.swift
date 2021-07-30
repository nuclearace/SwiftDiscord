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
import Logging

fileprivate let logger = Logger(label: "DiscordGateway")

/// Declares that a type will communicate with a Discord gateway.
public protocol DiscordGatewayable : DiscordEngineHeartbeatable {
    // MARK: Properties

    /// Creates the handshake object that Discord expects.
    /// Override if you need to customize the handshake object.
    var handshakeObject: [String: Any] { get }

    /// Creates the resume object that Discord expects.
    /// Override if you need to customize the resume object.
    var resumeObject: [String: Any] { get }

    // MARK: Methods

    ///
    /// Handles a DiscordNormalGatewayPayload. You shouldn't need to call this directly.
    ///
    /// Override this method if you need to customize payload handling.
    ///
    /// - parameter payload: The payload object
    ///
    func handleGatewayPayload(_ payload: DiscordNormalGatewayPayload)

    // MARK: Methods

    ///
    /// Handles a dispatch payload.
    ///
    /// - parameter payload: The dispatch payload
    ///
    func handleDispatch(_ payload: DiscordNormalGatewayPayload)

    ///
    /// Handles the hello event.
    ///
    /// - parameter payload: The dispatch payload
    ///
    func handleHello(_ payload: DiscordNormalGatewayPayload)

    ///
    /// Handles the resumed event.
    ///
    /// - parameter payload: The payload for the event.
    ///
    func handleResumed(_ payload: DiscordNormalGatewayPayload)

    ///
    /// Parses a raw message from the WebSocket. This is the entry point for all Discord events.
    /// You shouldn't call this directly.
    ///
    /// Override this method if you need to customize parsing.
    ///
    /// - parameter string: The raw payload string
    ///
    func parseGatewayMessage(_ string: String)

    ///
    /// Sends a payload to Discord.
    ///
    /// - parameter payload: The payload to send.
    ///
    func sendPayload(_ payload: DiscordNormalGatewayPayload)

    ///
    /// Starts the handshake with the Discord server. You shouldn't need to call this directly.
    ///
    /// Override this method if you need to customize the handshake process.
    ///
    func startHandshake()
}

public extension DiscordGatewayable where Self: DiscordWebSocketable & DiscordRunLoopable {
    /// Default Implementation.
    func sendPayload(_ payload: DiscordNormalGatewayPayload) {
        guard let payloadString = payload.createPayloadString() else {
            error(message: "Could not create payload string for payload: \(payload)")

            return
        }

        logger.debug("Sending ws: \(payloadString)")

        runloop.execute {
            self.websocket?.send(payloadString)
        }
    }
}

/// Holds a gateway payload, based on its type.
public enum DiscordGatewayPayloadData : Encodable {
    /// Outgoing payloads only, payload is a custom encodable type
    case customEncodable(Encodable)

    /// Payload is a json object.
    case object([String: Any])

    /// Payload is an integer.
    case integer(Int)

    /// The payload is a bool
    case bool(Bool)

    /// Payload is null.
    case null

    var value: Any {
        switch self {
        case let .customEncodable(encodable):
            return encodable
        case let .object(object):
            return object
        case let .integer(integer):
            return integer
        case let .bool(bool):
            return bool
        case .null:
            return NSNull()
        }
    }

    /// Encodable implementation.
    public func encode(to encoder: Encoder) throws {
        switch self {
        case let .customEncodable(encodable):
            try encodable.encode(to: encoder)
        case let .object(contents):
            try GenericEncodableDictionary(contents).encode(to: encoder)
        case let .integer(integer):
            var container = encoder.singleValueContainer()
            try container.encode(integer)
        case let .bool(bool):
            var container = encoder.singleValueContainer()
            try container.encode(bool)
        case .null:
            var container = encoder.singleValueContainer()
            try container.encodeNil()
        }
    }
}

extension DiscordGatewayPayloadData {
    static func dataFromDictionary(_ data: Any?) -> DiscordGatewayPayloadData {
        guard let data = data else { return .null }

        // TODO this is very ugly. See https://bugs.swift.org/browse/SR-5863
        switch data {
        case let object as [String: Any]:
            return .object(object)
        case let number as NSNumber where number === (true as NSNumber) || number === (false as NSNumber):
            return .bool(number.boolValue)
        case let integer as Int:
            return .integer(integer)
        default:
            return .null
        }
    }
}

/// Represents a gateway payload. This is lowest level of the Discord API.
public struct DiscordNormalGatewayPayload<Opcode>: Codable where Opcode: Codable {
    /// The opcode.
    public let opcode: Opcode

    /// The sequence number of this dispatch.
    public let sequenceNumber: Int?

    /// The event and payload data of this dispatch.
    public let event: DiscordDispatchEvent

    ///
    /// Creates a new DiscordNormalGatewayPayload.
    ///
    /// - parameter opcode: The opcode of this payload
    /// - parameter payload: The data of this payload
    /// - parameter sequenceNumber: An optional sequence number for this dispatch
    /// - parameter type: The event type of this dispatch
    ///
    public init(opcode: Opcode, sequenceNumber: Int? = nil, event: DiscordDispatchEvent) {
        self.opcode = opcode
        self.sequenceNumber = sequenceNumber
        self.event = event
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        opcode = try container.decode(Opcode.self, forKey: .opcode)
        sequenceNumber = try container.decode(Int?.self, forKey: .sequenceNumber)
        event = try DiscordDispatchEvent(from: container.superDecoder())
    }

    private enum CodingKeys: String, CodingKey {
        case opcode = "op"
        case payload = "d"
        case sequenceNumber = "s"
        case type = "t"
    }

    /// Encodable implementation.
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(opcode, forKey: .opcode)
        try container.encodeIfPresent(sequenceNumber, forKey: .sequenceNumber)
        try event.encode(to: container.superEncoder())
    }
}

public typealias DiscordNormalGatewayPayload = DiscordNormalGatewayPayload<DiscordNormalGatewayOpcode>
public typealias DiscordVoiceGatewayPayload = DiscordNormalGatewayPayload<DiscordVoiceGatewayOpcode>

/// Represents a regular gateway opcode
public enum DiscordNormalGatewayOpcode: Int, Codable {
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

/// Represents a voice gateway opcode
public enum DiscordVoiceGatewayOpcode: Int, Codable {
    /// Identify. Sent by the client.
    case identify = 0
    /// Select Protocol. Sent by the client.
    case selectProtocol = 1
    /// Ready. Sent by the server.
    case ready = 2
    /// Heartbeat. Sent by the client.
    case heartbeat = 3
    /// Session Description. Sent by the server.
    case sessionDescription = 4
    /// Speaking. Sent by both client and server.
    case speaking = 5
    /// Heartbeat ACK. Sent by the server.
    case heartbeatAck = 6
    /// Resume. Sent by the client.
    case resume = 7
    /// Hello. Sent by the server.
    case hello = 8
    /// Resumed. Sent by the server.
    case resumed = 9
    /// Client disconnect. Sent by the server.
    case clientDisconnect = 13
}

/// Represents the reason a gateway was closed.
public enum DiscordGatewayCloseReason: Int, Codable {
    /// We don't quite know why the gateway closed.
    case unknown = 0
    /// The gateway closed because the network dropped.
    case noNetwork = 50
    /// The gateway closed from a normal WebSocket close event.
    case normal = 1000
    /// Something went wrong, but we aren't quite sure either.
    case unknownError = 4000
    /// Discord got an opcode is doesn't recognize.
    case unknownOpcode = 4001
    /// We sent a payload Discord doesn't know what to do with.
    case decodeError = 4002
    /// We tried to send stuff before we were authenticated.
    case notAuthenticated = 4003
    /// We failed to authenticate with Discord.
    case authenticationFailed = 4004
    /// We tried to authenticate twice.
    case alreadyAuthenticated = 4005
    /// We sent a bad sequence number when trying to resume.
    case invalidSequence = 4007
    /// We sent messages too fast.
    case rateLimited = 4008
    /// Our session timed out.
    case sessionTimeout = 4009
    /// We sent an invalid shard when identifing.
    case invalidShard = 4010
    /// We sent a protocol Discord doesn't recognize.
    case unknownProtocol = 4012
    /// We got disconnected.
    case disconnected = 4014
    /// The voice server crashed.
    case voiceServerCrash = 4015
    /// We sent an encryption mode Discord doesn't know.
    case unknownEncryptionMode = 4016

    // MARK: Initializers

    init?(error: Error?) {
        #if !os(Linux)
        guard let error = error else { return nil }

        self.init(rawValue: (error as NSError).opcode)
        #else
        self = .unknown
        #endif
    }
}
