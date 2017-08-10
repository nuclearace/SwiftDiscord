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
    /// Handles a DiscordGatewayPayload. You shouldn't need to call this directly.
    ///
    /// Override this method if you need to customize payload handling.
    ///
    /// - parameter payload: The payload object
    ///
    func handleGatewayPayload(_ payload: DiscordGatewayPayload)

    // MARK: Methods

    ///
    /// Handles a dispatch payload.
    ///
    /// - parameter payload: The dispatch payload
    ///
    func handleDispatch(_ payload: DiscordGatewayPayload)

    ///
    /// Handles the hello event.
    ///
    /// - parameter payload: The dispatch payload
    ///
    func handleHello(_ payload: DiscordGatewayPayload)

    ///
    /// Handles the resumed event.
    ///
    /// - parameter payload: The payload for the event.
    ///
    func handleResumed(_ payload: DiscordGatewayPayload)

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
    func sendPayload(_ payload: DiscordGatewayPayload)

    ///
    /// Starts the handshake with the Discord server. You shouldn't need to call this directly.
    ///
    /// Override this method if you need to customize the handshake process.
    ///
    func startHandshake()
}

public extension DiscordGatewayable where Self: DiscordWebSocketable {
    /// Default Implementation.
    func sendPayload(_ payload: DiscordGatewayPayload) {
        guard let payloadString = payload.createPayloadString() else {
            error(message: "Could not create payload string")

            return
        }

        DefaultDiscordLogger.Logger.debug("Sending ws: \(payloadString)", type: description)

#if !os(Linux)
        websocket?.write(string: payloadString)
#else
        try? websocket?.send(payloadString)
#endif
    }
}

/// Holds a gateway payload, based on its type.
public enum DiscordGatewayPayloadData {
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
}

extension DiscordGatewayPayloadData {
    static func dataFromDictionary(_ data: Any?) -> DiscordGatewayPayloadData {
        guard let data = data else { return .null }

        switch data {
        case let object as [String: Any]:
            return .object(object)
        case let integer as Int:
            return .integer(integer)
        case let bool as Bool:
            return .bool(bool)
        default:
            return .null
        }
    }
}

/// Represents a gateway payload. This is lowest level of the Discord API.
public struct DiscordGatewayPayload {
    /// The payload code.
    public let code: DiscordGatewayCode

    /// The payload data.
    public let payload: DiscordGatewayPayloadData

    /// The sequence number of this dispatch.
    public let sequenceNumber: Int?

    /// The name of this dispatch.
    public let name: String?

    ///
    /// Creates a new DiscordGatewayPayload.
    ///
    /// - parameter code: The code of this payload
    /// - parameter payload: The data of this payload
    /// - parameter sequenceNumber: An optional sequence number for this dispatch
    /// - parameter name: The name of this dispatch
    ///
    public init(code: DiscordGatewayCode, payload: DiscordGatewayPayloadData, sequenceNumber: Int? = nil,
                name: String? = nil) {
        self.code = code
        self.payload = payload
        self.sequenceNumber = sequenceNumber
        self.name = name
    }

    func createPayloadString() -> String? {
        var payload: [String: Any] = [
            "op": code.rawCode,
            "d": self.payload.value
        ]

        if sequenceNumber != nil {
            payload["s"] = sequenceNumber!
        }

        if name != nil {
            payload["t"] = name!
        }

        return JSON.encodeJSON(payload)
    }
}

extension DiscordGatewayPayload {
    static func payloadFromString(_ string: String, fromGateway: Bool = true) -> DiscordGatewayPayload? {
        guard case let .object(dictionary)? = JSON.decodeJSON(string),
              let op = dictionary["op"] as? Int else { return nil }

        let code: DiscordGatewayCode
        let payload = DiscordGatewayPayloadData.dataFromDictionary(dictionary["d"])

        if fromGateway, let gatewayCode = DiscordNormalGatewayCode(rawValue: op) {
            code = .gateway(gatewayCode)
        } else if let voiceCode = DiscordVoiceGatewayCode(rawValue: op) {
            code = .voice(voiceCode)
        } else {
            return nil
        }

        return DiscordGatewayPayload(code: code, payload: payload, sequenceNumber: dictionary["s"] as? Int,
                                     name: dictionary["t"] as? String)
    }
}

/// Top-level enum for gateway codes.
public enum DiscordGatewayCode {
    /// Gateway code is a DiscordNormalGatewayCode.
    case gateway(DiscordNormalGatewayCode)

    /// Gateway code is a DiscordVoiceGatewayCode.
    case voice(DiscordVoiceGatewayCode)

    var rawCode: Int {
        switch self {
        case let .gateway(gatewayCode):
            return gatewayCode.rawValue
        case let .voice(voiceCode):
            return voiceCode.rawValue
        }
    }
}

/// Represents a regular gateway code
public enum DiscordNormalGatewayCode : Int {
    /// Dispatch.
    case dispatch
    /// Heartbeat.
    case heartbeat
    /// Identify.
    case identify
    /// Status Update.
    case statusUpdate
    /// Voice Status Update.
    case voiceStatusUpdate
    /// Voice Server Ping.
    case voiceServerPing
    /// Resume.
    case resume
    /// Reconnect.
    case reconnect
    /// Request Guild Members.
    case requestGuildMembers
    /// Invalid Session.
    case invalidSession
    /// Hello.
    case hello
    /// HeartbeatAck
    case heartbeatAck
}

/// Represents a voice gateway code
public enum DiscordVoiceGatewayCode : Int {
    /// Identify.
    case identify
    /// Select Protocol.
    case selectProtocol
    /// Ready.
    case ready
    /// Heartbeat.
    case heartbeat
    /// Session Description.
    case sessionDescription
    /// Speaking.
    case speaking
}

/// Represents the reason a gateway was closed.
public enum DiscordGatewayCloseReason : Int {
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

    // MARK: Initializers

    init?(error: NSError?) {
        guard let code = error?.code else { return nil }

        self.init(rawValue: code)
    }
}
