import Foundation
import Starscream

open class DiscordEngine : DiscordEngineSpec, DiscordEngineGatewayHandler {
	public private(set) weak var client: DiscordClientSpec?
	public private(set) var websocket: WebSocket?

	private let parseQueue = DispatchQueue(label: "discordEngine.parseQueue")
	private let handleQueue = DispatchQueue(label: "discordEngine.handleQueue")

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

			print("DiscordEngine: WebSocket disconnected \(err)")

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

		print("DiscordEngine: connecting with token \(client?.token)")

		websocket?.connect()
	}

	open func disconnect() {
		print("DiscordEngine: Disconnecting")

		websocket?.disconnect()
	}

	open func error() {
		print("DiscordEngine: errored")
	}

	open func handleGatewayPayload(_ payload: DiscordGatewayPayload) {
		handleQueue.async {
			self._handleGatewayPayload(payload)
		}
	}

	private func _handleGatewayPayload(_ payload: DiscordGatewayPayload) {
		switch payload.code {
		case .dispatch:
			handleDispatch(payload)
		default:
			break
		}
	}

	open func parseGatewayMessage(_ string: String) {
		print("DiscordEngine: Parsing")

		guard let decoded = DiscordGatewayPayload.payloadFromString(string) else { return }

		handleGatewayPayload(decoded)
	}

	open func startHandshake() {
		guard let client = self.client else { 
			// TODO error
			error()

			return
		}

		let handshakeEventData: [String: Any] = [
			"token": client.token,
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

		let payload = DiscordGatewayPayload(code: .identify, payload: handshakeEventData)

		guard let payloadString = payload.createPayloadString() else {
			error()

			return
		}

		websocket?.write(string: payloadString)
	}
}
