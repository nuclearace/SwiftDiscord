import Foundation
import Starscream

open class DiscordEngine : DiscordEngineSpec, DiscordEngineGatewayHandling, DiscordEngineHeartbeatable {
	public internal(set) var heartbeatInterval = 0 // Only touch on handleQueue

	public private(set) weak var client: DiscordClientSpec?
	public private(set) var heartbeatQueue = DispatchQueue(label: "discordEngine.heartbeatQueue")
	public private(set) var lastSequenceNumber = -1 // Only touch on handleQueue

	public internal(set) var websocket: WebSocket?

	let parseQueue = DispatchQueue(label: "discordEngine.parseQueue")
	let handleQueue = DispatchQueue(label: "discordEngine.handleQueue")

	public required init(client: DiscordClientSpec) {
		self.client = client
	}

	open func attachWebSocket() {
		print("DiscordEngine: Attaching WebSocket")

		websocket = WebSocket(url: URL(string: "wss://gateway.discord.gg")!)
		websocket?.callbackQueue = parseQueue

		attachWebSocketHandlers()
	}

	open func attachWebSocketHandlers() {
		websocket?.onConnect = {[weak self] in
			guard let this = self else { return }

			print("DiscordEngine: WebSocket Connected")

			this.startHandshake()
			// this.client?.handleEngineEvent("engine.connect", with: [])
		}

		websocket?.onDisconnect = {[weak self] err in
			guard let this = self else { return }

			print("DiscordEngine: WebSocket disconnected \(String(describing: err))")

			this.client?.handleEngineEvent("engine.disconnect", with: [])
		}

		websocket?.onText = {[weak self] string in
			guard let this = self else { return }

			// print("DiscordEngine: Got message: \(string)")

			this.parseGatewayMessage(string)
		}
	}

	open func connect() {
		attachWebSocket()

		print("DiscordEngine: connecting")

		websocket?.connect()
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
		print("DiscordEngine: Disconnecting")

		websocket?.disconnect()
	}

	open func error(message: String) {
		print("DiscordEngine: errored \(message)")
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
			print("Unhandled payload: \(payload.code)")
		}
	}

	open func parseGatewayMessage(_ string: String) {
		guard let decoded = DiscordGatewayPayload.payloadFromString(string) else {
			fatalError("What happened \(string)")
		}

		handleGatewayPayload(decoded)
	}

	open func sendHeartbeat() {
		guard websocket?.isConnected ?? false else { return }

		// print("DiscordEngineHeartbeatable: about to send heartbeat")

		sendGatewayPayload(DiscordGatewayPayload(code: .gateway(.heartbeat), payload: .integer(lastSequenceNumber)))

		let time = DispatchTime.now() + Double(Int64(heartbeatInterval * Int(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)

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
