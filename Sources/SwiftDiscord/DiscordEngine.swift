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
		return [
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
			// "shard": [1, 10]
		]
	}

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

	// MARK: Initializers

	/**
		Creates a new DiscordEngine.

		- parameter client: The DiscordClientSpec this engine should be associated with.
	*/
	public required init(client: DiscordClientSpec) {
		self.client = client
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

			DefaultDiscordLogger.Logger.log("WebSocket Connected", type: this.logType)

			this.startHandshake()
			// this.client?.handleEngineEvent("engine.connect", with: [])
		}

		websocket?.onDisconnect = {[weak self] err in
			guard let this = self else { return }

			DefaultDiscordLogger.Logger.log("WebSocket disconnected %@",
				type: this.logType, args: String(describing: err))

			this.handleClose()
		}

		websocket?.onText = {[weak self] string in
			guard let this = self else { return }

			DefaultDiscordLogger.Logger.debug("Got text: %@", type: this.logType, args: string)

			this.parseGatewayMessage(string)
		}
		#else
		websocket?.onText = {[weak self] ws, text in
			guard let this = self else { return }

			DefaultDiscordLogger.Logger.debug("Got text: %@", type: this.logType, args: text)

			this.parseGatewayMessage(text)
		}

		websocket?.onClose = {[weak self] _, _, _, _ in
			guard let this = self else { return }

			DefaultDiscordLogger.Logger.log("WebSocket closed", type: this.logType)

			this.handleClose()
		}
		#endif
	}

	/**
		Starts the connection to the Discord gateway.
	*/
	open func connect() {
		DefaultDiscordLogger.Logger.log("Connecting to %@", type: logType, args: connectURL)
		DefaultDiscordLogger.Logger.log("Attaching WebSocket", type: logType)

		#if !os(Linux)
		websocket = WebSocket(url: URL(string: connectURL)!)
		websocket?.callbackQueue = parseQueue

		attachWebSocketHandlers()
		websocket?.connect()
		#else
		try? WebSocket.background(to: connectURL) {[weak self] ws in
			DefaultDiscordLogger.Logger.log("Websocket connected", type: "DiscordEngine")

			self?.websocket = ws

			self?.attachWebSocketHandlers()
			self?.startHandshake()
		}
		#endif
	}

	/**
		Disconnects the engine. An `engine.disconnect` is fired on disconnection.
	*/
	open func disconnect() {
		DefaultDiscordLogger.Logger.log("Disconnecting", type: logType)

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

	private func handleClose() {
		client?.handleEngineEvent("\(engineType).disconnect", with: [])
		closed = true
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
		default:
			error(message: "Unhandled payload: \(payload.code)")
		}
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
		Sends a heartbeat to Discord. You shouldn't need to call this directly.

		Override this method if you need to customize heartbeats.
	*/
	open func sendHeartbeat() {
		guard !closed else { return }

		DefaultDiscordLogger.Logger.debug("Sending heartbeat", type: logType)

		sendGatewayPayload(DiscordGatewayPayload(code: .gateway(.heartbeat), payload: .integer(lastSequenceNumber)))

		let time = DispatchTime.now() + Double(heartbeatInterval)

		heartbeatQueue.asyncAfter(deadline: time) {[weak self] in self?.sendHeartbeat() }
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

		sendGatewayPayload(DiscordGatewayPayload(code: .gateway(.identify), payload: .object(handshakeObject)))
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
