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

/**
	The base class for Discord WebSocket communications.
*/
open class DiscordEngine : DiscordEngineSpec, DiscordEngineGatewayHandling, DiscordEngineHeartbeatable {
	// MARK: Properties

	/// The url for the gateway.
	open var connectURL: String {
		return DiscordEndpointGateway.gatewayURL + "/?v=6"
	}

	/// The type of DiscordEngineSpec. Used to correctly fire events.
	open var engineType: String {
		return "engine"
	}

	/// Creates the handshake object that Discord expects.
	/// Override if you need to customize the handshake object.
	open var handshakeObject: [String: Any] {
		var identify: [String: Any] = [
			"token": client!.token.token,
			"properties": [
				"$os": "macOS",
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
			"token": client!.token.token,
			"session_id": sessionId!,
			"seq": lastSequenceNumber
		]
	}

	/// The total number of shards.
	public let numShards: Int

	/// The shard number of this engine.
	public let shardNum: Int

	/// A reference to this engine's shard manager.
	public var manager: DiscordShardManager?

	/// This engine's session id.
	public var sessionId: String?

	// Only touch on handleQueue
	/// The interval (in seconds) to send heartbeats.
	public internal(set) var heartbeatInterval = 0

	/// The underlying WebSocket.
	///
	/// On Linux this is a WebSockets.WebSocket. While on macOS/iOS this is a Starscream.WebSocket
	public internal(set) var websocket: WebSocket?

	/// The client that this engine is associated with.
	public private(set) weak var client: DiscordClientSpec?

	/// The dispatch queue that heartbeats are sent on.
	public private(set) var heartbeatQueue = DispatchQueue(label: "discordEngine.heartbeatQueue")

	// Only touch on handleQueue
	/// The last sequence number received. Will be used for session resumes.
	public private(set) var lastSequenceNumber = -1

	let parseQueue = DispatchQueue(label: "discordEngine.parseQueue")
	let handleQueue = DispatchQueue(label: "discordEngine.handleQueue")

	var logType: String {
		return "DiscordEngine"
	}

	private var closed = false
	private var connectUUID = UUID()
	private var resuming = false

	// MARK: Initializers

	/**
		Creates a new DiscordEngine.

		- parameter client: The DiscordClientSpec this engine should be associated with.
	*/
	public required init(client: DiscordClientSpec, shardNum: Int = 0, numShards: Int = 1) {
		self.client = client
		self.shardNum = shardNum
		self.numShards = numShards
	}

	// MARK: Methods

	/**
		Attaches the WebSocket handlers that listen for text/connects/disconnects/etc

		Override if you need to provide custom handlers.

		Note: You should handle both WebSockets.WebSocket and Starscream.WebSocket handlers.
	*/
	open func attachWebSocketHandlers() {
		#if !os(Linux)
		websocket?.onConnect = {[weak self] in
			guard let this = self else { return }

			DefaultDiscordLogger.Logger.log("WebSocket Connected, shard: %@", type: this.logType, args: this.shardNum)

			this.connectUUID = UUID()

			this.startHandshake()
		}

		websocket?.onDisconnect = {[weak self] err in
			guard let this = self else { return }

			DefaultDiscordLogger.Logger.log("WebSocket disconnected %@, shard: %@",
				type: this.logType, args: String(describing: err), this.shardNum)

			this.handleClose(reason: err)
		}

		websocket?.onText = {[weak self] string in
			guard let this = self else { return }

			DefaultDiscordLogger.Logger.debug("Shard: %@ Got text: %@", type: this.logType, args: this.shardNum, string)

			this.parseGatewayMessage(string)
		}
		#else
		websocket?.onText = {[weak self] ws, text in
			guard let this = self else { return }

			DefaultDiscordLogger.Logger.debug("Shard: %@, Got text: %@", type: this.logType, args: this.shardNum, text)

			this.parseGatewayMessage(text)
		}

		websocket?.onClose = {[weak self] _, _, _, _ in
			guard let this = self else { return }

			DefaultDiscordLogger.Logger.log("WebSocket closed, shard: ", type: this.logType, args: this.shardNum)

			this.handleClose()
		}
		#endif
	}

	/**
		Starts the connection to the Discord gateway.
	*/
	open func connect() {
		DefaultDiscordLogger.Logger.log("Connecting to %@, shard: %@", type: logType, args: connectURL, shardNum)
		DefaultDiscordLogger.Logger.log("Attaching WebSocket, shard: %@", type: logType, args: shardNum)

		#if !os(Linux)
		websocket = WebSocket(url: URL(string: connectURL)!)
		websocket?.callbackQueue = parseQueue

		attachWebSocketHandlers()
		websocket?.connect()
		#else
		try? WebSocket.background(to: connectURL) {[weak self] ws in
			guard let this = self else { return }
			DefaultDiscordLogger.Logger.log("Websocket connected, shard: ", type: "DiscordEngine", args: this.shardNum)

			this.websocket = ws
			this.connectUUID = UUID()

			this.attachWebSocketHandlers()
			this.startHandshake()
		}
		#endif
	}

	/**
		Disconnects the engine. An `engine.disconnect` is fired on disconnection.
	*/
	open func disconnect() {
		DefaultDiscordLogger.Logger.log("Disconnecting, shard: %@", type: logType, args: shardNum)

		closed = true

		#if !os(Linux)
		websocket?.disconnect()
		#else
		try? websocket?.close()
		#endif
	}

	/**
		Logs that an error occured.

		- parameter message: The error message
	*/
	open func error(message: String) {
		DefaultDiscordLogger.Logger.error(message, type: logType)
	}

	/**
		Handles a close from the WebSocket.

		- parameter reason: The reason the socket closed.
	*/
	open func handleClose(reason: NSError? = nil) {
		let closeReason = DiscordGatewayCloseReason(error: reason) ?? .unknown

		if closeReason == .sessionTimeout {
			// Tell the client to clear their session id
			sessionId = nil
		}

		guard !closed else {
			manager?.signalShardDisconnected(shardNum: shardNum)

			return
		}

		resumeGateway()
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
				DefaultDiscordLogger.Logger.error("Invalid session received. Invalidating session", type: logType)

				sessionId = nil
			} else {
				DefaultDiscordLogger.Logger.error("Netsplit recieved, trying to resume", type: logType)
			}

			resuming = false
			startHandshake()
		}

		if let seq = payload.sequenceNumber {
			lastSequenceNumber = seq
		}

		guard case let .gateway(gatewayCode) = payload.code else {
			fatalError("Got voice payload in non voice engine")
		}

		switch gatewayCode {
		case .dispatch:
			handleDispatch(payload)
		case .hello:
			handleHello(payload)
		case .invalidSession:
			handleInvalidSession()
		case .heartbeat:
			sendGatewayPayload(DiscordGatewayPayload(code: .gateway(.heartbeat),
				payload: .integer(1)))
		case .heartbeatAck:
			DefaultDiscordLogger.Logger.debug("Got heartback ack", type: logType)
		default:
			error(message: "Unhandled payload: \(payload.code)")
		}
	}

	/**
		Handles the resumed event. You shouldn't call this directly.
	*/
	open func handleResumed(_ payload: DiscordGatewayPayload) {
		DefaultDiscordLogger.Logger.log("Resumed gateway session on shard: %@", type: logType, args: shardNum)

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

		DefaultDiscordLogger.Logger.log("Trying to resume gateway session on shard: %@", type: logType, args: shardNum)

		resuming = true

		_resumeGateway(wait: 0)
	}

	private func _resumeGateway(wait: Int) {
		handleQueue.asyncAfter(deadline: DispatchTime.now() + Double(wait)) {[weak self] in
			guard let this = self, this.resuming else { return }

			DefaultDiscordLogger.Logger.debug("Calling engine connect for gateway resume with wait: %@",
				type: this.logType, args: wait)

			this.connect()

			this._resumeGateway(wait: 10)
		}
	}

	/**
		Sends a heartbeat to Discord. You shouldn't need to call this directly.

		Override this method if you need to customize heartbeats.
	*/
	open func sendHeartbeat() {
		guard !closed else { return }

		DefaultDiscordLogger.Logger.debug("Sending heartbeat, shard: %@", type: logType, args: shardNum)

		sendGatewayPayload(DiscordGatewayPayload(code: .gateway(.heartbeat), payload: .integer(lastSequenceNumber)))

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
		guard client != nil else {
			error(message: "Client nil before handshaked")

			return
		}

		if sessionId != nil {
			DefaultDiscordLogger.Logger.log("Sending resume, shard: %@", type: logType, args: shardNum)

			sendGatewayPayload(DiscordGatewayPayload(code: .gateway(.resume), payload: .object(resumeObject)))
		} else {
			DefaultDiscordLogger.Logger.log("Sending handshake, shard: %@", type: logType, args: shardNum)

			sendGatewayPayload(DiscordGatewayPayload(code: .gateway(.identify), payload: .object(handshakeObject)))
		}
	}

	/**
		Starts the engine's heartbeat. You should call this method when you know the interval that Discord expects.

		- parameter seconds: The heartbeat interval
	*/
	open func startHeartbeat(seconds: Int) {
		heartbeatInterval = seconds

		sendHeartbeat()
	}
}
