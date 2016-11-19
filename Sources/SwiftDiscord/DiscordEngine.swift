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

open class DiscordEngine : DiscordEngineSpec, DiscordEngineGatewayHandling, DiscordEngineHeartbeatable {
	open var connectURL: String {
		return DiscordEndpointGateway.gatewayURL
	}

	open var engineType: String {
		return "engine"
	}

	public internal(set) var heartbeatInterval = 0 // Only touch on handleQueue
	public internal(set) var websocket: WebSocket?

	public private(set) weak var client: DiscordClientSpec?
	public private(set) var heartbeatQueue = DispatchQueue(label: "discordEngine.heartbeatQueue")
	public private(set) var lastSequenceNumber = -1 // Only touch on handleQueue

	let parseQueue = DispatchQueue(label: "discordEngine.parseQueue")
	let handleQueue = DispatchQueue(label: "discordEngine.handleQueue")

	var logType: String {
		return "DiscordEngine"
	}

	private var closed = false

	public required init(client: DiscordClientSpec) {
		self.client = client
	}

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

	open func createHandshakeObject() -> [String: Any] {
		return [
			"token": client!.token,
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

	open func disconnect() {
		DefaultDiscordLogger.Logger.log("Disconnecting", type: logType)

		#if !os(Linux)
		websocket?.disconnect()
		#else
		try? websocket?.close()
		#endif
	}

	open func error(message: String) {
		DefaultDiscordLogger.Logger.error(message, type: logType)
	}

	private func handleClose() {
		client?.handleEngineEvent("\(engineType).disconnect", with: [])
		closed = true
	}

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
		default:
			error(message: "Unhandled payload: \(payload.code)")
		}
	}

	open func parseGatewayMessage(_ string: String) {
		guard let decoded = DiscordGatewayPayload.payloadFromString(string) else {
			error(message: "Got unknown payload \(string)")

			return
		}

		handleGatewayPayload(decoded)
	}

	open func sendHeartbeat() {
		guard !closed else { return }

		DefaultDiscordLogger.Logger.debug("Sending heartbeat", type: logType)

		sendGatewayPayload(DiscordGatewayPayload(code: .gateway(.heartbeat), payload: .integer(lastSequenceNumber)))

		let time = DispatchTime.now() + Double(heartbeatInterval)

		heartbeatQueue.asyncAfter(deadline: time) {[weak self] in self?.sendHeartbeat() }
	}

	open func startHandshake() {
		guard client != nil else {
			error(message: "Client nil before handshaked")

			return
		}

		sendGatewayPayload(DiscordGatewayPayload(code: .gateway(.identify), payload: .object(createHandshakeObject())))
	}

	open func startHeartbeat(seconds: Int) {
		heartbeatInterval = seconds

		sendHeartbeat()
	}
}
