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
	public private(set) var ssrc: UInt32 = 0
	public private(set) var udpSocket: UDPClient?
	public private(set) var udpPort = -1
	public private(set) var voiceServerInformation: [String: Any]!

	private let readQueue = DispatchQueue(label: "discordVoiceEngine.readQueue")
	private let udpQueue = DispatchQueue(label: "discordVoiceEngine.udpQueue")
	private var readIO: DispatchIO?

	private var currentUnixTime: Int {
		return Int(Date().timeIntervalSince1970 * 1000)
	}

	private var ffmpeg: Process!
	private var firstPlay = true
	private var playingAudio = false
	private var reader: FileHandle!
	private var readPipe: Pipe!
	private var secret: [UInt8]!
	private var sequenceNum = UInt16(arc4random() >> 16)
	private var startTime = 0
	private var timestamp = arc4random()
	private var writePipe: Pipe!

	public convenience init?(client: DiscordClientSpec, voiceServerInformation: [String: Any]) {
		self.init(client: client)

		_ = sodium_init()

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

	private func audioSleep(_ count: Int) {
		let inner = (startTime + count * 20) - currentUnixTime
		let waitTime = Double(20 + inner) / 1000.0

		guard waitTime > 0 else { return }

		// print("sleeping \(waitTime)")
		Thread.sleep(forTimeInterval: waitTime)
	}

	public override func createHandshakeObject() -> [String: Any] {
		return [
			"session_id": client!.voiceState!.sessionId,
			"server_id": client!.voiceState!.guildId,
			"user_id": client!.user!.id,
			"token": voiceServerInformation["token"] as! String
		]
	}

	private func createRTPHeader() -> [UInt8] {
		func resetByteNumber(_ byteNumber: inout Int, _ currentHeaderIndex: inout Int, _ i: Int) {
			if i + 1 == 2 || i + 1 == 6 {
				byteNumber = 0
				currentHeaderIndex += 1
			} else {
				byteNumber += 1
				currentHeaderIndex += 1
			}
		}


		var rtpHeader = [UInt8](repeating: 0x00, count: 12)
		var byteNumber = 0
		var currentHeaderIndex = 2

		rtpHeader[0] = 0x80
		rtpHeader[1] = 0x78
		
		let sequenceBigEndian = sequenceNum.bigEndian
		let ssrcBigEndian = ssrc.bigEndian
		let timestampBigEndian = timestamp.bigEndian

		for i in 0..<10 {
			if i < 2 {
				rtpHeader[currentHeaderIndex] = UInt8((Int(sequenceBigEndian) >> (8 * byteNumber)) & 0xFF)

				resetByteNumber(&byteNumber, &currentHeaderIndex, i)
			} else if i < 6 {
				rtpHeader[currentHeaderIndex] = UInt8((Int(timestampBigEndian) >> (8 * byteNumber)) & 0xFF)

				resetByteNumber(&byteNumber, &currentHeaderIndex, i)
			} else {
				rtpHeader[currentHeaderIndex] = UInt8((Int(ssrcBigEndian) >> (8 * byteNumber)) & 0xFF)

				byteNumber += 1
				currentHeaderIndex += 1
			}
		}

		return rtpHeader
	}

	public override func disconnect() {
		print("DiscordVoiceEngine: Disconnecting")

		super.disconnect()

		do {
			try udpSocket?.close()
		} catch {}
		
		ffmpeg?.terminate()
		readIO?.close(flags: .stop)

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
		case .heartbeat:
			break
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
		self.ssrc = UInt32(ssrc)
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

	private func readData(_ count: Int) {
		// print(count)
		readIO?.read(offset: 0, length: 320, queue: readQueue) {done, data, int in
		    guard let data = data else { 
		    	print("no data, reader probably closed")

		    	self.sendGatewayPayload(DiscordGatewayPayload(code: .voice(.speaking), payload: .object([
		    		"speaking": false,
		    		"delay": 0
		    	])))

		    	self.firstPlay = true
		    	return
		    }

		    if data.count == 0 {
		    	fatalError("aaa aafdafads\n\n\n\n\n")
		    }

		    if self.firstPlay {
		    	self.startTime = self.currentUnixTime
		    	self.firstPlay = false

		    	self.sendGatewayPayload(DiscordGatewayPayload(code: .voice(.speaking), payload: .object([
		    		"speaking": true,
		    		"delay": 0
		    	])))
		    }
		    
		    // print(data)

		    self.sendVoiceData(Data(data))

		    self.sequenceNum = self.sequenceNum &+ 1
		    self.timestamp = self.timestamp &+ 960
		    self.audioSleep(count)

		    self.readData(count + 1)
		}
		// readQueue.async {


		// }
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

		// setup for audio
		requestNewWriter()
	}

	public override func sendHeartbeat() {
		guard websocket?.isConnected ?? false else { return }

		// print("About to send voice heartbeat")

		sendGatewayPayload(DiscordGatewayPayload(code: .voice(.heartbeat), payload: .integer(currentUnixTime)))

		let time = DispatchTime.now() + Double(Int64(heartbeatInterval * Int(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)

		heartbeatQueue.asyncAfter(deadline: time) {[weak self] in self?.sendHeartbeat() }
	}

	public func sendVoiceData(_ data: Data) {
		udpQueue.sync {
			guard self.playingAudio, let udpSocket = self.udpSocket, data.count > 0 else { return }

			// print("Should send voice data \(data)")

			data.withUnsafeBytes {(buf: UnsafePointer<UInt8>) in
				let encrypted = UnsafeMutablePointer<UInt8>.allocate(capacity: Int(crypto_secretbox_MACBYTES) + 320)
				let padding = [UInt8](repeating: 0x00, count: 12)

				guard data.count > 0 else { return }

				let rtpHeader = self.createRTPHeader()
				let enryptedCount = Int(crypto_secretbox_MACBYTES) + data.count

				var nonce = rtpHeader + padding
				_ = crypto_secretbox_easy(encrypted, buf, UInt64(data.count), &nonce, &self.secret!)
				let encryptedBytes = Array(UnsafeBufferPointer<UInt8>(start: encrypted, count: enryptedCount))

				do {
					try udpSocket.send(bytes: rtpHeader + encryptedBytes)
					// print("Sent \(encryptedBytes.count) bytes of voice")
				} catch {
					print("failed to send udp packet")
				}
			}
		}
	}

	// Only call on udpQueue
	public func requestNewWriter() {
		ffmpeg?.terminate()
		readIO?.close(flags: .stop)

		ffmpeg = Process()
		writePipe = Pipe()
		readPipe = Pipe()

		reader = writePipe.fileHandleForReading
		readIO = DispatchIO(type: .stream, fileDescriptor: reader.fileDescriptor, queue: readQueue, 
			cleanupHandler: {n in
				print("closed")
		})

		readIO?.setLimit(lowWater: 1)

		ffmpeg.launchPath = "/usr/local/bin/ffmpeg"
		ffmpeg.standardInput = readPipe.fileHandleForReading
		ffmpeg.standardOutput = writePipe.fileHandleForWriting
		ffmpeg.arguments = ["-hide_banner", "-i", "pipe:0", "-f", "data", "-map", "0:a", "-ar", 
			"48000", "-ac", "2", "-acodec", "libopus", "-sample_fmt", "s16", "-vbr", "off", "-b:a", "128000", 
			"-compression_level", "10", "pipe:1"]

		// TODO add termination handler to shutdown voice, since we can't do anything without ffmpeg
		ffmpeg.launch()

		ffmpeg.terminationHandler = {process in
			print("Process died")
		}

		playingAudio = true

		client?.handleEngineEvent("voiceEngine.writeHandle", with: [readPipe.fileHandleForWriting])

		readData(1)
	}

	public override func startHandshake() {
		guard client != nil else { return }

		// print("starting voice handshake")
		
		let handshakeEventData = createHandshakeObject()

		sendGatewayPayload(DiscordGatewayPayload(code: .voice(.identify), payload: .object(handshakeEventData)))
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
