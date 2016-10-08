import Foundation
import Starscream

public final class DiscordVoiceEngine : DiscordEngine, DiscordVoiceEngineSpec {
	public private(set) var voiceServerInformation: [String: Any]!

	public convenience init(client: DiscordClientSpec, voiceServerInformation: [String: Any]) {
		self.init(client: client)

		self.voiceServerInformation = voiceServerInformation
	}

	public override func attachWebSocket() {
		guard let endpoint = voiceServerInformation["endpoint"] as? String else {
			// TODO tell them the voice connection failed
			return
		}

		print("DiscordEngine: Attaching Voice WebSocket")

		// For some reason their wss:// endpoint fails on SSL handshaking
		// Probably Apple not liking a cert
		websocket = WebSocket(url: URL(string: "ws://" + endpoint)!)
		websocket?.callbackQueue = parseQueue

		attachWebSocketHandlers()
	}

	public override func attachWebSocketHandlers() {
		super.attachWebSocketHandlers()

		websocket?.onDisconnect = {[weak self] err in
			guard let this = self else { return }

			print("DiscordEngine: Voice WebSocket disconnected \(err)")

			this.client?.handleEngineEvent("voiceEngine.disconnect", with: [])
		}
	}

	public override func createHandshakeObject() -> [String: Any] {
		return [
			"session_id": client!.voiceState!.sessionId,
			"server_id": client!.voiceState!.guildId,
			"user_id": client!.user!.id,
			"token": voiceServerInformation["token"] as! String
		]
	}

	override func _handleGatewayPayload(_ payload: DiscordGatewayPayload) {
		switch payload.code {
		case .identify:
			handleIdentify(with: payload.payload)
		default:
			print("Got voice payload \(payload)")
		}
	}

	private func handleIdentify(with payload: DiscordGatewayPayloadData) {
		// TODO tell them the voice connection failed
		guard case let .object(voiceInformation) = payload, 
			let milliseconds = voiceInformation["heartbeat_interval"] as? Int, 
			let port = voiceInformation["port"] as? Int else { 
				return 
			}

		startHeartbeat(seconds: milliseconds / 1000)

		print(port)
	}

	public override func startHeartbeat(seconds: Int) {
		heartbeatInterval = seconds

		sendHeartbeat()
	}

	public func sendHeartbeat() {
		guard websocket?.isConnected ?? false else { return }

		print("About to send voice heartbeat")

		let payload = DiscordGatewayPayload(code: .voiceServerPing, payload: .integer(0))

		sendGatewayPayload(payload)

		let time = DispatchTime.now() + Double(Int64(heartbeatInterval * Int(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)

		heartbeatQueue.asyncAfter(deadline: time) {[weak self] in self?.sendHeartbeat() }
	}

	public override func startHandshake() {
		guard client != nil else { return }

		let handshakeEventData = createHandshakeObject()

		sendGatewayPayload(DiscordGatewayPayload(code: .dispatch, payload: .object(handshakeEventData)))
	}
}
