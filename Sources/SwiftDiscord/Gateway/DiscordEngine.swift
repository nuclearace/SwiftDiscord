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
#if !os(Linux)
import Starscream
#else
import WebSockets
#endif
import Dispatch

#if os(macOS)
private let os = "macOS"
#elseif os(iOS)
private let os = "iOS"
#else
private let os = "Linux"
#endif

/**
    The base class for Discord WebSocket communications.
*/
open class DiscordEngine : DiscordEngineSpec {
    // MARK: Properties

    /// The url for the gateway.
    open var connectURL: String {
        return DiscordEndpointGateway.gatewayURL + "/?v=6"
    }

    /// The type of DiscordEngineSpec. Used to correctly fire events.
    open var description: String {
        return "shard: \(shardNum)"
    }

    /// Creates the handshake object that Discord expects.
    /// Override if you need to customize the handshake object.
    open var handshakeObject: [String: Any] {
        var identify: [String: Any] = [
            "token": delegate!.token.token,
            "properties": [
                "$os": os,
                "$browser": "SwiftDiscord",
                "$device": "SwiftDiscord",
                "$referrer": "",
                "$referring_domain": ""
            ],
            "compress": false,
            "large_threshold": 250,
        ]

        if numShards > 1 {
            identify["shard"] = [shardNum, numShards]
        }

        return identify
    }

    /// Creates the resume object that Discord expects.
    /// Override if you need to customize the resume object.
    open var resumeObject: [String: Any] {
        return [
            "token": delegate!.token.token,
            "session_id": sessionId!,
            "seq": lastSequenceNumber
        ]
    }

    /// The dispatch queue that heartbeats are sent on.
    public let heartbeatQueue = DispatchQueue(label: "discordEngine.heartbeatQueue")

    /// The total number of shards.
    public let numShards: Int

    /// The shard number of this engine.
    public let shardNum: Int

    /// The queue that WebSockets use to parse things.
    public let parseQueue = DispatchQueue(label: "discordEngine.parseQueue")

    /// The UUID of this WebSocketable.
    public var connectUUID = UUID()

    /// This engine's session id.
    public var sessionId: String?

    /// The underlying WebSocket.
    ///
    /// On Linux this is a WebSockets.WebSocket. While on macOS/iOS this is a Starscream.WebSocket
    public var websocket: WebSocket?

    /// Whether this engine is connected to the gateway.
    public internal(set) var connected = false

    // Only touch on handleQueue
    /// The interval (in seconds) to send heartbeats.
    public internal(set) var heartbeatInterval = 0

    /// The delegate that this engine is associated with.
    public private(set) weak var delegate: DiscordShardDelegate?

    // Only touch on handleQueue
    /// The last sequence number received. Will be used for session resumes.
    public private(set) var lastSequenceNumber = -1

    let handleQueue = DispatchQueue(label: "discordEngine.handleQueue")

    var logType: String {
        return "DiscordEngine"
    }

    var pongsMissed = 0

    private var closed = false
    private var resuming = false

    // MARK: Initializers

    /**
        Creates a new DiscordEngine.

        - parameter delegate: The DiscordClientSpec this engine should be associated with.
    */
    public required init(delegate: DiscordShardDelegate, shardNum: Int = 0, numShards: Int = 1) {
        self.delegate = delegate
        self.shardNum = shardNum
        self.numShards = numShards
    }

    // MARK: Methods

    /**
        Disconnects the engine. An `engine.disconnect` is fired on disconnection.
    */
    public func disconnect() {
        DefaultDiscordLogger.Logger.log("Disconnecting, \(description)", type: "DiscordWebSocketable")

        closed = true

        closeWebSockets()
    }

    /**
        Handles a close from the WebSocket.

        - parameter reason: The reason the socket closed.
    */
    open func handleClose(reason: NSError? = nil) {
        let closeReason = DiscordGatewayCloseReason(error: reason) ?? .unknown

        connected = false
        heartbeatQueue.sync { self.pongsMissed = 0 }

        DefaultDiscordLogger.Logger.log("Disconnected, shard: \(shardNum)", type: logType)

        if closeReason == .sessionTimeout {
            sessionId = nil
        }

        guard !closed else {
            delegate?.shardDidDisconnect(self)

            return
        }

        resumeGateway()
    }

    /**
        Handles a dispatch payload.

        - parameter payload: The dispatch payload
    */
    open func handleDispatch(_ payload: DiscordGatewayPayload) {
        guard let type = payload.name, let event = DiscordDispatchEvent(rawValue: type) else {
            DefaultDiscordLogger.Logger.error("Could not create dispatch event \(payload)", type: logType)

            return
        }

        if event == .ready, case let .object(payloadObject) = payload.payload,
           let sessionId = payloadObject["session_id"] as? String {
            delegate?.shardDidConnect(self)
            self.sessionId = sessionId
        } else if event == .resumed {
            handleResumed(payload)
        }

        delegate?.shard(self, didReceiveEvent: event, with: payload)
    }

    /**
        Handles a DiscordGatewayPayload. You shouldn't need to call this directly.

        Override this method if you need to customize payload handling.

        - parameter payload: The payload object
    */
    open func handleGatewayPayload(_ payload: DiscordGatewayPayload) {
        handleQueue.async {
            self._handleGatewayPayload(payload)
        }
    }

    func _handleGatewayPayload(_ payload: DiscordGatewayPayload) {
        func handleInvalidSession() {
            if case let .bool(netsplit) = payload.payload, !netsplit {
                DefaultDiscordLogger.Logger.log("Invalid session received. Invalidating session", type: logType)

                sessionId = nil
            } else {
                DefaultDiscordLogger.Logger.log("Netsplit recieved, trying to resume", type: logType)
            }

            resuming = false
            startHandshake()
        }

        guard case let .gateway(gatewayCode) = payload.code else {
            fatalError("Got voice payload in non voice engine")
        }

        if let seq = payload.sequenceNumber {
            lastSequenceNumber = seq
        }

        switch gatewayCode {
        case .dispatch:
            handleDispatch(payload)
        case .hello:
            handleHello(payload)
        case .invalidSession:
            handleInvalidSession()
        case .heartbeat:
            sendPayload(DiscordGatewayPayload(code: .gateway(.heartbeat), payload: .integer(lastSequenceNumber)))
        case .heartbeatAck:
            heartbeatQueue.sync { self.pongsMissed = 0 }
            DefaultDiscordLogger.Logger.debug("Got heartback ack", type: logType)
        default:
            error(message: "Unhandled payload: \(payload.code)")
        }
    }

    /**
        Handles the hello event.

        - parameter payload: The dispatch payload
    */
    open func handleHello(_ payload: DiscordGatewayPayload) {
        guard case let .object(eventData) = payload.payload else { fatalError("Got bad hello payload") }
        guard let milliseconds = eventData["heartbeat_interval"] as? Int else {
            fatalError("Got bad heartbeat interval")
        }

        connected = true

        startHeartbeat(seconds: milliseconds / 1000)
        delegate?.shard(self, gotHelloWithPayload: payload)
    }

    /**
        Handles the resumed event. You shouldn't call this directly.
    */
    open func handleResumed(_ payload: DiscordGatewayPayload) {
        DefaultDiscordLogger.Logger.log("Resumed gateway session on shard: \(shardNum)", type: logType)

        resuming = false

        sendHeartbeat()
    }

    /**
        Parses a raw message from the WebSocket. This is the entry point for all Discord events.
        You shouldn't call this directly.

        Override this method if you need to customize parsing.

        - parameter string: The raw payload string
    */
    open func parseGatewayMessage(_ string: String) {
        guard let decoded = DiscordGatewayPayload.payloadFromString(string) else {
            error(message: "Got unknown payload \(string)")

            return
        }

        handleGatewayPayload(decoded)
    }

    /**
        Tries to resume a disconnected gateway connection.
    */
    open func resumeGateway() {
        guard !resuming && !closed else {
            DefaultDiscordLogger.Logger.debug("Already trying to resume or closed, ignoring", type: logType)

            return
        }

        DefaultDiscordLogger.Logger.log("Trying to resume gateway session on shard: \(shardNum)", type: logType)

        resuming = true

        _resumeGateway(wait: 0)
    }

    private func _resumeGateway(wait: Int) {
        handleQueue.asyncAfter(deadline: DispatchTime.now() + Double(wait)) {[weak self] in
            guard let this = self, this.resuming else { return }

            DefaultDiscordLogger.Logger.debug("Calling engine connect for gateway resume with wait: \(wait)",
                type: this.logType)

            this.connect()

            this._resumeGateway(wait: 10)
        }
    }

    /**
        Sends a heartbeat to Discord. You shouldn't need to call this directly.

        Override this method if you need to customize heartbeats.
    */
    open func sendHeartbeat() {
        guard connected else {
            DefaultDiscordLogger.Logger.debug("Tried heartbeating on disconnected shard, shard: \(shardNum)", type: logType)

            return
        }

        guard pongsMissed < 2 else {
            DefaultDiscordLogger.Logger.log("Too many pongs missed; closing, shard: \(shardNum)", type: logType)

            pongsMissed = 0
            closeWebSockets()

            return
        }

        DefaultDiscordLogger.Logger.debug("Sending heartbeat, shard: \(shardNum)", type: logType)

        pongsMissed += 1
        sendPayload(DiscordGatewayPayload(code: .gateway(.heartbeat), payload: .integer(lastSequenceNumber)))

        let time = DispatchTime.now() + Double(heartbeatInterval)

        heartbeatQueue.asyncAfter(deadline: time) {[weak self, uuid = connectUUID] in
            guard let this = self, uuid == this.connectUUID else { return }

            this.sendHeartbeat()
        }
    }

    /**
        Starts the handshake with the Discord server. You shouldn't need to call this directly.

        Override this method if you need to customize the handshake process.
    */
    open func startHandshake() {
        guard delegate != nil else {
            error(message: "delegate nil before handshaked")

            return
        }

        if sessionId != nil {
            DefaultDiscordLogger.Logger.log("Sending resume, shard: \(shardNum)", type: logType)

            sendPayload(DiscordGatewayPayload(code: .gateway(.resume), payload: .object(resumeObject)))
        } else {
            DefaultDiscordLogger.Logger.log("Sending handshake, shard: \(shardNum)", type: logType)

            sendPayload(DiscordGatewayPayload(code: .gateway(.identify), payload: .object(handshakeObject)))
        }
    }

    /**
        Starts the engine's heartbeat. You should call this method when you know the interval that Discord expects.

        - parameter seconds: The heartbeat interval
    */
    public func startHeartbeat(seconds: Int) {
        heartbeatInterval = seconds

        sendHeartbeat()
    }
}
