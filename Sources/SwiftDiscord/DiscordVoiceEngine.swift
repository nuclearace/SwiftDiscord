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

/// A named tuple that contains the RTP header and voice data from a voice packet.
/// The voice data is OPUS encoded.
public typealias DiscordVoiceData = (rtpHeader: [UInt8], voiceData: [UInt8])

#if !os(iOS)

import Foundation
import Dispatch
#if os(macOS)
import Starscream
#else
import WebSockets
#endif
import Socks
import Sodium

enum DiscordVoiceEngineError : Error {
	case decryptionError
	case encryptionError
	case ipExtraction
}

/**
	A subclass of `DiscordEngine` that provides functionality for voice communication.

	Discord uses encrypted OPUS encoded voice packets. The engine is responsible for encyrpting/decrypting voice
	packets that are sent and received.
*/
public final class DiscordVoiceEngine : DiscordEngine, DiscordVoiceEngineSpec {
	// MARK: Properties

	/// The voice url
	public override var connectURL: String {
		return "wss://" + endpoint.components(separatedBy: ":")[0]
	}

	/// The type of `DiscordEngine` this is. Used to correctly fire engine events.
	public override var engineType: String {
		return "voiceEngine"
	}

	/// Creates the handshake object that Discord expects.
	public override var handshakeObject: [String: Any] {
		return [
			"session_id": client!.voiceState!.sessionId,
			"server_id": client!.voiceState!.guildId,
			"user_id": client!.user!.id,
			"token": voiceServerInformation["token"] as! String
		]
	}

	/// The encoder for this engine. The encoder is responsible for turning raw audio data into OPUS encoded data
	public private(set) var encoder: DiscordVoiceEncoder?

	/// The raw voice endpoint gotten from Discord
	public private(set) var endpoint: String!

	/// The modes that are available for communication. Only xsalsa20_poly1305 is supported currently
	public private(set) var modes = [String]()

	/// The secret key used for encryption
	public private(set) var secret: [UInt8]!

	/// Our SSRC
	public private(set) var ssrc: UInt32 = 0

	/// The UDP socket that is used to send/receive voice data
	public private(set) var udpSocket: UDPClient?

	/// Our UDP port
	public private(set) var udpPort = -1

	/// Information about the voice server we are connected to
	public private(set) var voiceServerInformation: [String: Any]!

	override var logType: String {
		return "DiscordVoiceEngine"
	}

	private let encoderSemaphore = DispatchSemaphore(value: 1)
	private let padding = [UInt8](repeating: 0x00, count: 12)

	private let udpQueue = DispatchQueue(label: "discordVoiceEngine.udpQueue")
	private let udpQueueRead = DispatchQueue(label: "discordVoiceEngine.udpQueueRead")

	private var currentUnixTime: Int {
		return Int(Date().timeIntervalSince1970 * 1000)
	}

	private var closed = false
	// This property can be accessed from multiple queues, therefore use encoderSemaphore to manage access
	// Hopefully when Swift has property behaviors this can be made prettier
	private var makeEncoder = true {
		willSet {
			encoderSemaphore.wait()
		}

		didSet {
			encoderSemaphore.signal()
		}
	}

    #if os(macOS)
	private var sequenceNum = UInt16(arc4random() >> 16)
	private var timestamp = arc4random()
    #else
    private var sequenceNum = UInt16(random() >> 16)
    private var timestamp = UInt32(random())
    #endif

	private var startTime = 0

	// MARK: Initializers

	/**
		Constructs a new VoiceEngine

		- parameter client: The client this engine should be associated with
		- parameter voiceServerInformation: The voice server information
		- parameter encoder: A DiscordVoiceEncoder that from a previous engine. Send if you are still encoding i.e
					moved channels
		- parameter secret: The secret from a previous engine.
	*/
	public convenience init?(client: DiscordClientSpec, voiceServerInformation: [String: Any],
			encoder: DiscordVoiceEncoder?, secret: [UInt8]?) {
		self.init(client: client)

		_ = sodium_init()

		signal(SIGPIPE, SIG_IGN)

		self.voiceServerInformation = voiceServerInformation
		self.encoder = encoder
		self.secret = secret

		if let endpoint = voiceServerInformation["endpoint"] as? String {
			self.endpoint = endpoint
		} else {
			return nil
		}
	}

	deinit {
		disconnect()
	}

	// MARK: Methods

	private func audioSleep(_ count: Int) {
		let inner = (startTime + count * 20) - currentUnixTime
		let waitTime = Double(20 + inner) / 1000.0

		guard waitTime > 0 else { return }

		DefaultDiscordLogger.Logger.debug("Sleeping %@ %@", type: logType, args: waitTime, count)
		Thread.sleep(forTimeInterval: waitTime)
	}

	private func createEncoder() {
		// Any reads that get EOF because of the encoder dying should not trigger a new encoder
		makeEncoder = false
		// This will trigger a block while the old encoder is released and cleans itself up
		// It's important that we first set it to nil, otherwise the new encoder will exist at the same time as the old
		// one. Which causes weirdness
		encoder = nil
		encoder = DiscordVoiceEncoder()

		readData(1)

		client?.handleEvent("voiceEngine.ready", with: [])

		// Reenable automatic encoder creation
		makeEncoder = true
	}

	private func createRTPHeader() -> [UInt8] {
		defer { header.deallocate() }

		let header = UnsafeMutableRawBufferPointer.allocate(count: 12)

		header.storeBytes(of: 0x80, as: UInt8.self)
		header.storeBytes(of: 0x78, toByteOffset: 1, as: UInt8.self)
		header.storeBytes(of: sequenceNum.bigEndian, toByteOffset: 2, as: UInt16.self)
		header.storeBytes(of: timestamp.bigEndian, toByteOffset: 4, as: UInt32.self)
		header.storeBytes(of: ssrc.bigEndian, toByteOffset: 8, as: UInt32.self)

		return Array(header)
	}

	private func decryptVoiceData(_ data: Data) throws {
		defer { free(unencrypted) }

		let rtpHeader = Array(data.prefix(12))
		let voiceData = Array(data.dropFirst(12))
		let audioSize = voiceData.count - Int(crypto_secretbox_MACBYTES)
		let unencrypted = UnsafeMutablePointer<UInt8>.allocate(capacity: audioSize)
		var nonce = rtpHeader + padding

		let success = crypto_secretbox_open_easy(unencrypted, voiceData, UInt64(data.count - 12), &nonce, &self.secret!)

		// Decryption failure
		guard success != -1 else { throw DiscordVoiceEngineError.decryptionError }

		self.client?.handleVoiceData(DiscordVoiceData(rtpHeader: rtpHeader,
			voiceData: Array(UnsafeBufferPointer<UInt8>(start: unencrypted, count: audioSize))))
	}

	/**
		Disconnects the voice engine.
	*/
	public override func disconnect() {
		DefaultDiscordLogger.Logger.log("Disconnecting VoiceEngine", type: logType)

		super.disconnect()

		closeOutEngine()
	}

	private func closeOutEngine() {
		do {
			try udpSocket?.close()
		} catch {
			self.error(message: "Error trying to close voice engine udp socket")
		}

		closed = true
		connected = false
		encoder = nil
	}

	private func createVoicePacket(_ data: [UInt8]) throws -> [UInt8] {
		defer { free(encrypted) }

		let audioSize = Int(crypto_secretbox_MACBYTES) + defaultAudioSize
		let encrypted = UnsafeMutablePointer<UInt8>.allocate(capacity: audioSize)
		let rtpHeader = createRTPHeader()
		let enryptedCount = Int(crypto_secretbox_MACBYTES) + data.count
		var nonce = rtpHeader + padding
		var buf = data

		let success = crypto_secretbox_easy(encrypted, &buf, UInt64(buf.count), &nonce, &secret!)

		guard success != -1 else { throw DiscordVoiceEngineError.encryptionError }

		let encryptedBytes = Array(UnsafeBufferPointer(start: encrypted, count: enryptedCount))

		return rtpHeader + encryptedBytes
	}

	private func extractIPAndPort(from bytes: [UInt8]) throws -> (String, Int) {
		DefaultDiscordLogger.Logger.debug("Extracting ip and port from %@", type: logType, args: bytes)

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

	/**
		Handles a close from the WebSocket.

		- parameter reason: The reason the socket closed.
	*/
	public override func handleClose(reason: NSError? = nil) {
		DefaultDiscordLogger.Logger.log("Voice engine closed", type: logType)

		closeOutEngine()
	}

	private func handleDoneReading() {
		// Should we make a new encoder?
		// If no, that means a new encoder has already been requested, creating a new one could lead to a race where we
		// get stuck in a loop of making new encoders
		encoderSemaphore.wait()
		guard makeEncoder else {
			encoderSemaphore.signal()
			return
		}

		encoderSemaphore.signal()
		createEncoder()
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
			DefaultDiscordLogger.Logger.debug("Unhandled voice payload %@", type: logType, args: payload)
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

	/**
		Parses a raw message from the WebSocket. This is the entry point for voice events.
		You shouldn't call this directly.
	*/
	public override func parseGatewayMessage(_ string: String) {
		guard let decoded = DiscordGatewayPayload.payloadFromString(string, fromGateway: false) else {
			DefaultDiscordLogger.Logger.log("Got unknown payload %@", type: logType, args: string)

			return
		}

		handleGatewayPayload(decoded)
	}

	private func readData(_ count: Int) {
		encoder?.read {[weak self] done, data in
			guard let this = self, this.connected else { return } // engine died

		    guard !done else {
		    	DefaultDiscordLogger.Logger.debug("No data, reader probably closed", type: this.logType)

		    	this.sendGatewayPayload(DiscordGatewayPayload(code: .voice(.speaking), payload: .object([
		    		"speaking": false,
		    		"delay": 0
		    	])))

		    	this.handleDoneReading()

		    	return
		    }

		    DefaultDiscordLogger.Logger.debug("Read %@ bytes", type: this.logType, args: data.count)

		    if count == 1 {
		    	this.startTime = this.currentUnixTime

		    	this.sendGatewayPayload(DiscordGatewayPayload(code: .voice(.speaking), payload: .object([
		    		"speaking": true,
		    		"delay": 0
		    	])))
		    }

		    this.sendVoiceData(data)
		    this.audioSleep(count)
		    this.readData(count + 1)
		}
	}

	private func readSocket() {
		udpQueueRead.async {[weak self] in
			guard let socket = self?.udpSocket, self?.connected ?? false else { return }

			do {
				let (data, _) = try socket.receive(maxBytes: 4096)

				try self?.decryptVoiceData(Data(bytes: data))
			} catch {
				self?.error(message: "Error reading voice data from udp socket")
			}

			self?.readSocket()
		}
	}

	/**
		Used to request a new `FileHandle` that can be used to write directly to the encoder. Which will in turn be
		sent to Discord.

		Example using youtube-dl to play music:

		```swift
		youtube = EncoderProcess()
		youtube.launchPath = "/usr/local/bin/youtube-dl"
		youtube.arguments = ["-f", "bestaudio", "-q", "-o", "-", link]
		youtube.standardOutput = client.voiceEngine!.requestFileHandleForWriting()!

		youtube.terminationHandler = {[weak self] process in
		    self?.client.voiceEngine?.encoder?.finishEncodingAndClose()
		}

		youtube.launch()
		```

		- returns: An optional containing a FileHandle that can be written to, or nil if there is no encoder.
	*/
	public func requestFileHandleForWriting() -> FileHandle? {
		return encoder?.readPipe.fileHandleForWriting
	}

	/**
		Stops encoding and requests a new encoder. A `voiceEngine.ready` event will be fired when the encoder is ready.
	*/
	public func requestNewEncoder() {
		createEncoder()
	}

	// Tells the voice websocket what our ip and port is, and what encryption mode we will use
	// currently only xsalsa20_poly1305 is supported
	// After this point we are good to go in sending encrypted voice packets
	private func selectProtocol(with ip: String, on port: Int) {
		// print("Selecting UDP protocol with ip: \(ip) on port: \(port)")

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
		connected = true

		if encoder == nil {
			// We are the first engine the client had, or they didn't give us an encoder to use
			createEncoder()
		} else {
			// We inherited a previous engine's encoder, read from it
			readData(1)
		}

		readSocket()
	}

	/**
		Sends a voice heartbeat to Discord. You shouldn't need to call this directly.
	*/
	public override func sendHeartbeat() {
		guard !closed else { return }

		sendGatewayPayload(DiscordGatewayPayload(code: .voice(.heartbeat), payload: .integer(currentUnixTime)))

		let time = DispatchTime.now() + Double(heartbeatInterval)

		heartbeatQueue.asyncAfter(deadline: time) {[weak self] in self?.sendHeartbeat() }
	}

	/**
		Sends OPUS encoded voice data to Discord. Because of the assumptions built into the engine, the voice data
		should have a max length of `defaultAudioSize`.

		- parameter data: An array of OPUS encoded voice data.
	*/
	public func sendVoiceData(_ data: [UInt8]) {
		udpQueue.sync {
			guard let udpSocket = self.udpSocket, data.count <= defaultAudioSize else { return }

			DefaultDiscordLogger.Logger.debug("Should send voice data: %@ bytes", type: self.logType, args: data.count)

            do {
            	try udpSocket.send(bytes: self.createVoicePacket(data))
            } catch {
            	self.error(message: "Failed sending voice packet")
            }

            self.sequenceNum = self.sequenceNum &+ 1
            self.timestamp = self.timestamp &+ 960
		}
	}

	/**
		Starts the handshake with the Discord voice server. You shouldn't need to call this directly.
	*/
	public override func startHandshake() {
		guard client != nil else { return }

		DefaultDiscordLogger.Logger.log("Starting voice handshake", type: logType)

		sendGatewayPayload(DiscordGatewayPayload(code: .voice(.identify), payload: .object(handshakeObject)))
	}

	private func startUDP() {
		guard udpPort != -1 else { return }

		let base = endpoint.components(separatedBy: ":")[0]
		let udpEndpoint = InternetAddress(hostname: base, port: UInt16(udpPort))

		guard let client = try? UDPClient(address: udpEndpoint) else {
			disconnect()

			return
		}

		udpSocket = client

		// Begin async UDP setup
		findIP()
	}
}

#endif
