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
import NIO
import Logging
import WebSocketKit
import Dispatch

#if os(macOS)
private let os = "macOS"
#elseif os(iOS)
private let os = "iOS"
#else
private let os = "Linux"
#endif

fileprivate let logger = Logger(label: "DiscordEngine")

///
/// The base class for Discord WebSocket communications.
///
public class DiscordEngine: DiscordShard {
    // MARK: Properties

    /// The url for the gateway.
    public var connectURL: String { DiscordEndpointGateway.gatewayURL + "/?v=8&encoding=json" }

    /// The type of DiscordEngineSpec. Used to correctly fire events.
    public var description: String { "shard: \(shardNum)" }

    /// The handshake object that Discord expects.
    public var identify: DiscordGatewayIdentify {
        DiscordGatewayIdentify(
            token: delegate!.token,
            intents: intents,
            properties: .init(
                os: os,
                browser: "swift-discord",
                device: "swift-discord"
            ),
            compress: false,
            largeThreshold: 250,
            shard: numShards > 1 ? [shardNum, numShards] : nil
        )
    }

    /// The resume object that Discord expects.
    public var resume: DiscordGatewayResume {
        DiscordGatewayResume(
            token: delegate!.token,
            sessionId: sessionId!,
            sequenceNumber: lastSequenceNumber
        )
    }

    /// The dispatch queue that heartbeats are sent on.
    public let heartbeatQueue = DispatchQueue(label: "discordEngine.heartbeatQueue")

    /// The total number of shards.
    public let numShards: Int

    /// The run loop for this shard.
    public let runloop: EventLoop

    /// The shard number of this engine.
    public let shardNum: Int

    /// The intents used when connecting to the gateway.
    public let intents: DiscordGatewayIntents

    /// The queue that WebSockets use to parse things.
    public let parseQueue = DispatchQueue(label: "discordEngine.parseQueue")

    /// The UUID of this WebSocketable.
    public var connectUUID = UUID()

    /// This engine's session id.
    public var sessionId: String?

    /// The underlying WebSocket.
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

    ///
    /// Creates a new DiscordEngine.
    ///
    /// - parameter delegate: The DiscordClientSpec this engine should be associated with.
    ///
    public required init(delegate: DiscordShardDelegate, shardNum: Int = 0, numShards: Int = 1, intents: DiscordGatewayIntents, onLoop: EventLoop) {
        self.delegate = delegate
        self.shardNum = shardNum
        self.numShards = numShards
        self.intents = intents
        self.runloop = onLoop
    }

    // MARK: Methods

    ///
    /// Disconnects the engine. An `engine.disconnect` is fired on disconnection.
    ///
    public func disconnect() {
        logger.info("Disconnecting, \(description)")

        closed = true

        closeWebSockets()
    }

    ///
    /// Handles a close from the WebSocket.
    ///
    /// - parameter reason: The reason the socket closed.
    ///
    public func handleClose(reason: Error? = nil) {
        let closeReason = DiscordGatewayCloseReason(error: reason) ?? .unknown

        connected = false

        logger.info("Disconnected, shard: \(shardNum)")

        if closeReason == .sessionTimeout {
            sessionId = nil
        }

        guard !closed else {
            delegate?.shardDidDisconnect(self)

            return
        }

        resumeGateway()
    }

    ///
    /// Handles a dispatch payload.
    ///
    /// - parameter event: The dispatch payload
    ///
    private func handleDispatch(_ event: DiscordDispatchEvent) {
        switch event {
        case .ready(let ready):
            delegate?.shardDidConnect(self)
            sessionId = ready.sessionId
        case .resumed:
            handleResumed()
        default:
            break
        }

        delegate?.shard(self, didReceiveEvent: event)
    }

    ///
    /// Handles a DiscordGatewayEvent. You shouldn't need to call this directly.
    ///
    /// - parameter event: The payload object
    ///
    public func handleGatewayPayload(_ event: DiscordGatewayEvent) {
        handleQueue.async {
            self._handleGatewayPayload(event)
        }
    }

    func _handleGatewayPayload(_ event: DiscordGatewayEvent) {
        switch event {
        case .dispatch(let e):
            lastSequenceNumber = e.sequenceNumber
            handleDispatch(e.event)
        case .hello(let e):
            handleHello(e)
        case .invalidSession(let e):
            handleInvalidSession(e)
        case .heartbeat:
            sendPayload(.heartbeat(DiscordGatewayHeartbeat(lastSequenceNumber: lastSequenceNumber)))
        case .heartbeatAck:
            heartbeatQueue.sync { self.pongsMissed = 0 }
            logger.debug("Got heartbeat ack")
        default:
            logger.error("Unhandled payload: \(event)")
        }
    }

    ///
    /// Handles an invalid session event.
    ///
    /// - parameter event: The handled event.
    ///
    private func handleInvalidSession(_ event: DiscordGatewayInvalidSession) {
        if event.isResumable {
            logger.info("Netsplit recieved, trying to resume")
        } else {
            logger.info("Invalid session received. Invalidating session")

            sessionId = nil
        }

        resuming = false
        startHandshake()
    }

    ///
    /// Handles the hello event.
    ///
    /// - parameter hello: The dispatch payload
    ///
    private func handleHello(_ hello: DiscordGatewayHello) {
        heartbeatQueue.sync { self.pongsMissed = 0 }
        connected = true

        startHeartbeat(milliseconds: hello.heartbeatInterval)
        delegate?.shard(self, gotHello: hello)
    }

    ///
    /// Handles the resumed event. You shouldn't call this directly.
    ///
    private func handleResumed() {
        logger.info("Resumed gateway session on shard: \(shardNum)")

        heartbeatQueue.sync { self.pongsMissed = 0 }
        resuming = false

        sendHeartbeat()
    }

    ///
    /// Parses a raw message from the WebSocket. This is the entry point for all Discord events.
    /// You shouldn't call this directly.
    ///
    /// - parameter string: The raw payload string
    ///
    public func parseAndHandleGatewayMessage(_ string: String) {
        guard let data = string.data(using: .utf8) else {
            logger.error("Could not decode gateway event: \(string)")
            return
        }

        do {
            let decoded = try DiscordJSON.makeDecoder().decode(DiscordGatewayEvent.self, from: data)
            handleGatewayPayload(decoded)
        } catch {
            logger.error("Could not decode gateway event: \(error)")
        }
    }

    ///
    /// Tries to resume a disconnected gateway connection.
    ///
    private func resumeGateway() {
        guard !resuming && !closed else {
            logger.info("Already trying to resume or closed, ignoring")

            return
        }

        logger.info("Trying to resume gateway session on shard: \(shardNum)")

        resuming = true

        _resumeGateway(wait: 0)
    }

    private func _resumeGateway(wait: Int) {
        handleQueue.asyncAfter(deadline: DispatchTime.now() + Double(wait)) {[weak self] in
            guard let this = self, this.resuming else { return }

            logger.debug("Calling engine connect for gateway resume with wait: \(wait)")

            this.connect()
            this._resumeGateway(wait: 10)
        }
    }

    ///
    /// Sends a heartbeat to Discord. You shouldn't need to call this directly.
    ///
    /// Override this method if you need to customize heartbeats.
    ///
    public func sendHeartbeat() {
        guard connected else {
            logger.error("Tried heartbeating on disconnected shard, shard: \(shardNum)")

            return
        }

        guard pongsMissed < 2 else {
            logger.info("Too many pongs missed; closing, shard: \(shardNum)")

            pongsMissed = 0
            closeWebSockets(fast: true)

            return
        }

        logger.debug("Sending heartbeat, shard: \(shardNum)")

        pongsMissed += 1
        sendPayload(.heartbeat(DiscordGatewayHeartbeat(lastSequenceNumber: lastSequenceNumber)))

        let time = DispatchTime.now() + .milliseconds(heartbeatInterval)

        heartbeatQueue.asyncAfter(deadline: time) {[weak self, uuid = connectUUID] in
            guard let this = self, uuid == this.connectUUID else { return }

            this.sendHeartbeat()
        }
    }

    ///
    /// Starts the handshake with the Discord server. You shouldn't need to call this directly.
    ///
    public func startHandshake() {
        guard delegate != nil else {
            logger.error("delegate nil before handshaked")
            return
        }

        if sessionId != nil {
            logger.info("Sending resume, shard: \(shardNum)")

            sendPayload(.resume(resume))
        } else {
            logger.info("Sending handshake, shard: \(shardNum)")

            sendPayload(.identify(identify))
        }
    }

    ///
    /// Starts the engine's heartbeat. You should call this method when you know the interval that Discord expects.
    ///
    /// - parameter milliseconds: The heartbeat interval
    ///
    public func startHeartbeat(milliseconds: Int) {
        logger.debug("Starting heartbeat, shard: \(shardNum), \(milliseconds)ms")

        heartbeatInterval = milliseconds

        sendHeartbeat()
    }
}
