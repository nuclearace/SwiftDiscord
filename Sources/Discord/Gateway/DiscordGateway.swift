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
    func parseAndHandleGatewayMessage(_ string: String)

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

public extension DiscordGatewayable where Self: DiscordWebSocketable & DiscordRunLoopable {
    /// Default Implementation.
    func sendPayload(_ payload: DiscordGatewayPayload) {
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

/// Represents a gateway payload. This is lowest level of the Discord API.
public struct DiscordGatewayPayload: Codable {
    /// The opcode.
    public let opcode: DiscordGatewayOpcode

    /// The sequence number of this dispatch.
    public let sequenceNumber: Int?

    /// The event and payload data of this dispatch.
    public let event: DiscordDispatchEvent?

    ///
    /// Creates a new DiscordGatewayPayload.
    ///
    /// - parameter opcode: The opcode of this payload
    /// - parameter sequenceNumber: An optional sequence number for this dispatch
    /// - parameter event: The event type and data
    ///
    public init(opcode: Opcode, sequenceNumber: Int? = nil, event: DiscordDispatchEvent? = nil) {
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
        case sequenceNumber = "s"
    }

    /// Encodable implementation.
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(opcode, forKey: .opcode)
        try container.encodeIfPresent(sequenceNumber, forKey: .sequenceNumber)
        try event.encode(to: container.superEncoder())
    }
}
