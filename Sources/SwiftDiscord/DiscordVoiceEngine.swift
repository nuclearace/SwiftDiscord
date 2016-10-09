import Foundation
import Starscream
import Socks
import Sodium

enum DiscordVoiceEngineError : Error {
	case ipExtraction
}

public final class DiscordVoiceEngine : DiscordEngine, DiscordVoiceEngineSpec {
	public private(set) var endpoint: String!
	public private(set) var modes = [String]()
	public private(set) var ssrc = -1
	public private(set) var udpSocket: UDPClient?
	public private(set) var udpPort = -1
	public private(set) var voiceServerInformation: [String: Any]!

	private let udpQueue = DispatchQueue(label: "discordVoiceEngine.udpQueue")

	private var currentUnixTime: Int {
		return Int(String(Date().timeIntervalSince1970).replacingOccurrences(of: ".", with: ""))!
	}

	private var secret: [UInt8]?

	public convenience init?(client: DiscordClientSpec, voiceServerInformation: [String: Any]) {
		self.init(client: client)

		self.voiceServerInformation = voiceServerInformation

		if let endpoint = voiceServerInformation["endpoint"] as? String {
			self.endpoint = endpoint
		} else {
			return nil
		}
	}

	public override func attachWebSocket() {
		print("DiscordVoiceEngine: Attaching WebSocket")

		websocket = WebSocket(url: URL(string: "wss://" + endpoint.components(separatedBy: ":")[0])!)
		websocket?.callbackQueue = parseQueue

		attachWebSocketHandlers()
	}

	public override func attachWebSocketHandlers() {
		super.attachWebSocketHandlers()

		websocket?.onDisconnect = {[weak self] err in
			guard let this = self else { return }

			print("DiscordVoiceEngine: WebSocket disconnected \(err)")

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

	public override func disconnect() {
		print("DiscordVoiceEngine: Disconnecting")

		super.disconnect()

		do {
			try udpSocket?.close()
		} catch {}
		

		client?.handleEngineEvent("voiceEngine.disconnect", with: [])
	}

	private func extractIPAndPort(from bytes: [UInt8]) throws -> (String, Int) {
		// print("extracting our ip and port from \(bytes)")

		let ipData = Data(bytes: bytes.dropLast(2))
		let portBytes = Array(bytes.suffix(from: bytes.endIndex.advanced(by: -2)))
		let port = (Int(portBytes[0]) | Int(portBytes[1])) &<< 8

		guard let ipString = String(data: ipData, encoding: .utf8)?.replacingOccurrences(of: "\0", with: "") else {
			throw DiscordVoiceEngineError.ipExtraction
		}

		return (ipString, port)
	}

	// https://discordapp.com/developers/docs/topics/voice-connections#ip-discovery
	private func findIP() {
		udpQueue.async {
			guard let udpSocket = self.udpSocket else { return }

			// print("Finding IP")
			let discoveryData = [UInt8](repeating: 0x00, count: 70)

			do {
				try udpSocket.send(bytes: discoveryData)

				let (data, _) = try udpSocket.receive(maxBytes: 70)
				let (ip, port) = try self.extractIPAndPort(from: data)

				self.selectProtocol(with: ip, on: port)
			} catch {
				// print("Something blew up")
				self.disconnect()
			}
		}
	}

	override func _handleGatewayPayload(_ payload: DiscordGatewayPayload) {
		guard case let .voice(voiceCode) = payload.code else {
			fatalError("Got gateway payload in non gateway engine")
		}

		switch voiceCode {
		case .ready:
			handleReady(with: payload.payload)
		case .sessionDescription:
			udpQueue.async { self.handleVoiceSessionDescription(with: payload.payload) }
		default:
			// print("Got voice payload \(payload)")
			break
		}
	}

	private func handleReady(with payload: DiscordGatewayPayloadData) {
		guard case let .object(voiceInformation) = payload,
			let heartbeatInterval = voiceInformation["heartbeat_interval"] as? Int,
			let ssrc = voiceInformation["ssrc"] as? Int, let udpPort = voiceInformation["port"] as? Int,
			let modes = voiceInformation["modes"] as? [String] else {
				// TODO tell them the voice connection failed
				disconnect()

				return 
			}

		self.udpPort = udpPort
		self.modes = modes
		self.ssrc = ssrc
		self.heartbeatInterval = heartbeatInterval

		startUDP()
	}

	private func handleVoiceSessionDescription(with payload: DiscordGatewayPayloadData) {
		guard case let .object(voiceInformation) = payload, 
			let secret = voiceInformation["secret_key"] as? [Int] else {
				// TODO tell them we failed
				disconnect()

				return
			}

		self.secret = secret.map({ UInt8($0) })
	}

	public override func parseGatewayMessage(_ string: String) {
		guard let decoded = DiscordGatewayPayload.payloadFromString(string, fromGateway: false) else { 
			fatalError("What happened \(string)") 
		}

		handleGatewayPayload(decoded)
	}

	// Tells the voice websocket what our ip and port is, and what encryption mode we will use
	// currently only xsalsa20_poly1305 is supported
	// After this point we are good to go in sending encrypted voice packets
	private func selectProtocol(with ip: String, on port: Int) {
		print("Selecting UDP protocol with ip: \(ip) on port: \(port)")

		let payloadData: [String: Any] = [
			"protocol": "udp",
			"data": [
				"address": ip,
				"port": port,
				"mode": "xsalsa20_poly1305"
			]
		]

		sendGatewayPayload(DiscordGatewayPayload(code: .voice(.selectProtocol), payload: .object(payloadData)))
		startHeartbeat(seconds: heartbeatInterval / 1000)
	}

	public override func sendHeartbeat() {
		guard websocket?.isConnected ?? false else { return }

		// print("About to send voice heartbeat")

		sendGatewayPayload(DiscordGatewayPayload(code: .voice(.heartbeat), payload: .integer(currentUnixTime)))

		let time = DispatchTime.now() + Double(Int64(heartbeatInterval * Int(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)

		heartbeatQueue.asyncAfter(deadline: time) {[weak self] in self?.sendHeartbeat() }
	}

	public override func startHandshake() {
		guard client != nil else { return }

		// print("starting voice handshake")
		
		let handshakeEventData = createHandshakeObject()

		sendGatewayPayload(DiscordGatewayPayload(code: .voice(.identify), payload: .object(handshakeEventData)))
	}

	public override func startHeartbeat(seconds: Int) {
		heartbeatInterval = seconds

		sendHeartbeat()
	}

	private func startUDP() {
		guard udpPort != -1 else { return }

		let base = endpoint.components(separatedBy: ":")[0]
		let udpEndpoint = InternetAddress(hostname: base, port: UInt16(udpPort))

		guard let client = try? UDPClient(address: udpEndpoint) else {
			self.disconnect()

			return
		}

		udpSocket = client

		// Begin async UDP setup
		findIP()
	}
}
