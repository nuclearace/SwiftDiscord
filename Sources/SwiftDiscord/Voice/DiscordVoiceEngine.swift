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
import Dispatch
#if !os(Linux)
import Starscream
#else
import WebSockets
#endif
import Sockets
import Sodium

enum DiscordVoiceEngineError : Error {
    case decryptionError
    case encryptionError
    case ipExtraction
}

///
/// A subclass of `DiscordEngine` that provides functionality for voice communication.
///
/// Discord uses encrypted OPUS encoded voice packets. The engine is responsible for encyrptingdecrypting voice
/// packets that are sent and received.
///
public final class DiscordVoiceEngine : DiscordVoiceEngineSpec {
    // MARK: Properties

    /// The configuration for this engine.
    public let config: DiscordVoiceEngineConfiguration

    /// The heartbeat queue.
    public let heartbeatQueue = DispatchQueue(label: "discordVoiceEngine.heartbeatQueue")

    /// The parse queue.
    public let parseQueue = DispatchQueue(label: "discordVoiceEngine.parseQueue")

    /// The voice url
    public var connectURL: String {
        return "wss://" + voiceServerInformation.endpoint.components(separatedBy: ":")[0]
    }

    /// The connect UUID of this WebSocketable.
    public var connectUUID = UUID()

    /// The type of `DiscordEngine` this is. Used to correctly fire engine events.
    public var description: String {
        return "voiceEngine"
    }

    /// The id of the guild this voice engine is for.
    public var guildId: GuildID {
        return voiceState.guildId
    }

    /// Creates the handshake object that Discord expects.
    public var handshakeObject: [String: Any] {
        return [
            "session_id": voiceState.sessionId,
            "server_id": String(describing: voiceState.guildId),
            "user_id": String(describing: voiceState.userId),
            "token": voiceServerInformation.token
        ]
    }

    /// Not used in voice gateways
    public var resumeObject: [String: Any] {
        return [:]
    }

    /// The underlying websocket.
    public var websocket: WebSocket?

    /// The voice engine's delegate.
    public private(set) weak var voiceDelegate: DiscordVoiceEngineDelegate?

    /// The heartbeat interval for this engine.
    public private(set) var heartbeatInterval = -1

    /// The data source for this engine. This source is responsible for giving us Opus data that is ready to send.
    public private(set) var source: DiscordVoiceEngineDataSource!

    /// The modes that are available for communication. Only xsalsa20_poly1305 is supported currently
    public private(set) var modes = [String]()

    /// The secret key used for encryption
    public private(set) var secret: [UInt8]!

    /// Our SSRC
    public private(set) var ssrc: UInt32 = 0

    /// The UDP socket that is used to send/receive voice data
    public private(set) var udpSocket: UDPInternetSocket?

    /// Our UDP port
    public private(set) var udpPort = -1

    /// Information about the voice server we are connected to
    public private(set) var voiceServerInformation: DiscordVoiceServerInformation!

    /// The voice state for this engine.
    public private(set) var voiceState: DiscordVoiceState!

    private static let logType = "DiscordVoiceEngine"
    private static let padding = [UInt8](repeating: 0x00, count: 12)

    private let decoderSession = DiscordVoiceSessionDecoder()
    private let encoderSemaphore = DispatchSemaphore(value: 1)
    private let udpQueueWrite = DispatchQueue(label: "discordVoiceEngine.udpQueueWrite")
    private let udpQueueRead = DispatchQueue(label: "discordVoiceEngine.udpQueueRead")
    private let writeQueue = DispatchQueue(label: "discordVoiceEngine.writeQueue")

    private var audioCount = -1
    private var currentUnixTime: Int {
        return Int(Date().timeIntervalSince1970 * 1000)
    }

    private var connected = false
    private var closed = false

    #if !os(Linux)
    private var sequenceNum = UInt16(arc4random() >> 16)
    private var timestamp = arc4random()
    #else
    private var sequenceNum = UInt16(random() >> 16)
    private var timestamp = UInt32(random())
    #endif

    private var sendTimer: DispatchSourceTimer!
    private var startTime = 0

    // MARK: Initializers

    ///
    /// Constructs a new VoiceEngine
    ///
    /// - parameter delegate: The client this engine should be associated with
    /// - parameter voiceServerInformation: The voice server information
    /// - parameter encoder: A DiscordVoiceEncoder that from a previous engine. Send if you are still encoding i.e
    /// moved channels
    /// - parameter secret: The secret from a previous engine.
    ///
    public init(delegate: DiscordVoiceEngineDelegate,
                config: DiscordVoiceEngineConfiguration,
                voiceServerInformation: DiscordVoiceServerInformation,
                voiceState: DiscordVoiceState,
                source: DiscordVoiceEngineDataSource?,
                secret: [UInt8]?) {
        self.voiceDelegate = delegate
        self.config = config

        _ = sodium_init()

        signal(SIGPIPE, SIG_IGN)

        self.voiceState = voiceState
        self.voiceServerInformation = voiceServerInformation
        self.source = source
        self.secret = secret
    }

    deinit {
        DefaultDiscordLogger.Logger.debug("deinit", type: DiscordVoiceEngine.logType)

        closeOutEngine()
    }

    // MARK: Methods

    private func audioSleep() {
        guard audioCount != -1 else {
            // First time
            sendSpeaking(true) // Make sure we're speaking
            audioCount = 1
            startTime = currentUnixTime

            return
        }

        let inner = (startTime + audioCount * 20) - currentUnixTime
        let waitTime = Double(20 + inner) / 1000.0

        guard waitTime > 0 else {
            // Been too long since we last sent, set a new baseline
            audioCount = 1
            startTime = currentUnixTime

            return
        }

        DefaultDiscordLogger.Logger.debug("Sleeping \(waitTime) \(audioCount)", type: DiscordVoiceEngine.logType)

        Thread.sleep(forTimeInterval: waitTime)

        audioCount += 1
    }

    private func getNewSource() throws {
        defer { encoderSemaphore.signal() }

        // Guard against trying to create multiple encoders at once
        encoderSemaphore.wait()

        createTimer()

        source = try voiceDelegate?.voiceEngineNeedsDataSource(self)

        readData()

        voiceDelegate?.voiceEngineReady(self)
    }

    private func createTimer() {
        self.sendTimer = DispatchSource.makeTimerSource(flags: .strict, queue: udpQueueWrite)
        self.sendTimer.setEventHandler {[weak self] in
            guard let this = self else { return }

            do {
                this.sendVoiceData(try this.source.engineNeedsData(this))
            } catch DiscordVoiceEngineDataSourceStatus.done {
                DefaultDiscordLogger.Logger.debug("Voice Engine done", type: DiscordVoiceEngine.logType)

                this.handleDoneReading()
            } catch DiscordVoiceEngineDataSourceStatus.noData {
                DefaultDiscordLogger.Logger.debug("No data", type: DiscordVoiceEngine.logType)
            } catch {
                DefaultDiscordLogger.Logger.error("Error getting voice data: \(error)",
                                                  type: DiscordVoiceEngine.logType)
            }
        }

        self.sendTimer.scheduleRepeating(wallDeadline: .now(), interval: .milliseconds(20))

        // TODO this is wasteful, figure out if there's a smart way to start and stop the timer.
        // Maybe let the user decide?
        sendTimer.resume()
    }

    private func createRTPHeader() -> [UInt8] {
        let header = UnsafeMutableRawBufferPointer.allocate(count: 12)

        defer { header.deallocate() }

        header.storeBytes(of: 0x80, as: UInt8.self)
        header.storeBytes(of: 0x78, toByteOffset: 1, as: UInt8.self)
        header.storeBytes(of: sequenceNum.bigEndian, toByteOffset: 2, as: UInt16.self)
        header.storeBytes(of: timestamp.bigEndian, toByteOffset: 4, as: UInt32.self)
        header.storeBytes(of: ssrc.bigEndian, toByteOffset: 8, as: UInt32.self)

        return Array(header)
    }

    private func closeOutEngine() {
        guard !closed else { return }

        do {
            try udpSocket?.close()
        } catch {
            self.error(message: "Error trying to close voice engine udp socket")
        }

        closed = true
        connected = false
        source.finishUpAndClose()
    }

    private func createVoicePacket(_ data: [UInt8]) throws -> [UInt8] {
        let packetSize = Int(crypto_secretbox_MACBYTES) + data.count
        let encrypted = UnsafeMutablePointer<UInt8>.allocate(capacity: packetSize)
        let rtpHeader = createRTPHeader()
        var nonce = rtpHeader + DiscordVoiceEngine.padding
        var buf = data

        defer { free(encrypted) }

        let success = crypto_secretbox_easy(encrypted, &buf, UInt64(buf.count), &nonce, &secret!)

        guard success != -1 else { throw DiscordVoiceEngineError.encryptionError }

        return rtpHeader + Array(UnsafeBufferPointer(start: encrypted, count: packetSize))
    }

    private func decryptVoiceData(_ data: [UInt8]) throws -> [UInt8] {
        let rtpHeader = Array(data.prefix(12))
        let voiceData = Array(data.dropFirst(12))
        let audioSize = voiceData.count - Int(crypto_secretbox_MACBYTES)
        let unencrypted = UnsafeMutablePointer<UInt8>.allocate(capacity: audioSize)
        var nonce = rtpHeader + DiscordVoiceEngine.padding

        defer { free(unencrypted) }

        let success = crypto_secretbox_open_easy(unencrypted, voiceData, UInt64(data.count - 12), &nonce, &secret!)

        guard success != -1 else { throw DiscordVoiceEngineError.decryptionError }

        return rtpHeader + Array(UnsafeBufferPointer(start: unencrypted, count: audioSize))
    }

    ///
    /// Disconnects the voice engine.
    ///
    public func disconnect() {
        DefaultDiscordLogger.Logger.log("Disconnecting VoiceEngine", type: DiscordVoiceEngine.logType)

        closeWebSockets()
        closeOutEngine()

        voiceDelegate?.voiceEngineDidDisconnect(self)
    }

    private func extractIPAndPort(from bytes: [UInt8]) throws -> (String, Int) {
        DefaultDiscordLogger.Logger.debug("Extracting ip and port from \(bytes)", type: DiscordVoiceEngine.logType)

        let ipData = Data(bytes: bytes.dropLast(2))
        let portBytes = Array(bytes.suffix(from: bytes.endIndex.advanced(by: -2)))
        let port = (Int(portBytes[0]) | Int(portBytes[1])) << 8

        guard let ipString = String(data: ipData, encoding: .utf8)?.replacingOccurrences(of: "\0", with: "") else {
            throw DiscordVoiceEngineError.ipExtraction
        }

        return (ipString, port)
    }

    // https://discordapp.com/developers/docs/topics/voice-connections#ip-discovery
    private func findIP() {
        udpQueueWrite.async {
            guard let udpSocket = self.udpSocket else { return }

            // print("Finding IP")
            let discoveryData = [UInt8](repeating: 0x00, count: 70)

            do {
                try udpSocket.sendto(data: discoveryData)

                let (data, _) = try udpSocket.recvfrom(maxBytes: 70)
                let (ip, port) = try self.extractIPAndPort(from: data)

                self.selectProtocol(with: ip, on: port)
            } catch {
                self.error(message: "Something went wrong extracting the ip and port")
                self.disconnect()
            }
        }
    }

    ///
    /// Handles a close from the WebSocket.
    ///
    /// - parameter reason: The reason the socket closed.
    ///
    public func handleClose(reason: NSError? = nil) {
        DefaultDiscordLogger.Logger.log("Voice engine closed", type: DiscordVoiceEngine.logType)

        closeOutEngine()
    }

    /// Currently unused in VoiceEngines.
    public func handleDispatch(_ payload: DiscordGatewayPayload) { }

    /// Currently unused in VoiceEngines.
    public func handleHello(_ payload: DiscordGatewayPayload) { }

    private func handleDoneReading() {
        sendSilence()
        // Add a new pipe on the encoder and put a read on it.
         do {
             try requestNewEncoder()
         } catch let err {
             error(message: "Error getting new data source: \(err)")
             disconnect()

             return
         }

        voiceDelegate?.voiceEngineReady(self)
    }

    ///
    /// Handles a DiscordGatewayPayload. You shouldn't need to call this directly.
    ///
    /// Override this method if you need to customize payload handling.
    ///
    /// - parameter payload: The payload object
    ///
    public func handleGatewayPayload(_ payload: DiscordGatewayPayload) {
        guard case let .voice(voiceCode) = payload.code else {
            fatalError("Got gateway payload in non gateway engine")
        }

        switch voiceCode {
        case .ready:
            handleReady(with: payload.payload)
        case .sessionDescription:
            udpQueueWrite.sync { self.handleVoiceSessionDescription(with: payload.payload) }
            sendSilence()
        case .speaking:
            DefaultDiscordLogger.Logger.debug("Got speaking \(payload)", type: DiscordVoiceEngine.logType)
        default:
            DefaultDiscordLogger.Logger.debug("Unhandled voice payload \(payload)", type: DiscordVoiceEngine.logType)
        }
    }

    private func handleReady(with payload: DiscordGatewayPayloadData) {
        guard case let .object(voiceInformation) = payload,
              let heartbeatInterval = voiceInformation["heartbeat_interval"] as? Int,
              let ssrc = voiceInformation["ssrc"] as? Int,
              let udpPort = voiceInformation["port"] as? Int,
              let modes = voiceInformation["modes"] as? [String] else {
            disconnect()

            return
        }

        self.udpPort = udpPort
        self.modes = modes
        self.ssrc = UInt32(ssrc)
        self.heartbeatInterval = heartbeatInterval

        startUDP()
    }

    /// Currently unused in VoiceEngines.
    public func handleResumed(_ payload: DiscordGatewayPayload) { }

    private func handleVoiceSessionDescription(with payload: DiscordGatewayPayloadData) {
        guard case let .object(voiceInformation) = payload,
              let secret = voiceInformation["secret_key"] as? [Int] else {
            disconnect()

            return
        }

        self.secret = secret.map({ UInt8($0) })
    }

    ///
    /// Parses a raw message from the WebSocket. This is the entry point for voice events.
    /// You shouldn't call this directly.
    ///
    public func parseGatewayMessage(_ string: String) {
        guard let decoded = DiscordGatewayPayload.payloadFromString(string, fromGateway: false) else {
            DefaultDiscordLogger.Logger.log("Got unknown payload \(string)", type: DiscordVoiceEngine.logType)

            return
        }

        handleGatewayPayload(decoded)
    }

    private func readData() {
        source.startReading()
    }

    private func readSocket() {
        // TODO refactor to be non-blocking
        udpQueueRead.async {[weak self] in
            guard let socket = self?.udpSocket, self?.connected ?? false else { return }

            do {
                let (data, _) = try socket.recvfrom(maxBytes: 4096)

                DefaultDiscordLogger.Logger.debug("Received data \(data)", type: "DiscordVoiceEngine")

                guard let this = self else { return }

                let packet = DiscordOpusVoiceData(voicePacket: try this.decryptVoiceData(data))

                if this.config.decodeVoice {
                    this.voiceDelegate?.voiceEngine(this,
                                                    didReceiveRawVoiceData: try this.decoderSession.decode(packet))
                } else {
                    this.voiceDelegate?.voiceEngine(this, didReceiveOpusVoiceData: packet)
                }
            } catch DiscordVoiceError.initialPacket {
                DefaultDiscordLogger.Logger.debug("Got initial packet", type: "DiscordVoiceEngine")
            } catch DiscordVoiceError.decodeFail {
                DefaultDiscordLogger.Logger.debug("Failed to decode a packet", type: "DiscordVoiceEngine")
            } catch DiscordVoiceEngineError.decryptionError {
                self?.error(message: "Error decrypting voice packet")
            } catch let err {
                self?.error(message: "Error reading voice data from udp socket \(err)")
                self?.disconnect()

                return
            }

            self?.readSocket()
        }
    }

    ///
    /// Stops encoding and requests a new encoder. The `isReadyToSendVoiceWithEngine` delegate method is called when
    /// the new encoder is ready.
    ///
    public func requestNewEncoder() throws {
        try getNewSource()
    }

    // Tells the voice websocket what our ip and port is, and what encryption mode we will use
    // currently only xsalsa20_poly1305 is supported
    // After this point we are good to go in sending encrypted voice packets
    private func selectProtocol(with ip: String, on port: Int) {
        DefaultDiscordLogger.Logger.debug("Selecting UDP protocol with ip: \(ip) on port: \(port)",
                                          type: DiscordVoiceEngine.logType)

        let payloadData: [String: Any] = [
            "protocol": "udp",
            "data": [
                "address": ip,
                "port": port,
                "mode": "xsalsa20_poly1305"
            ]
        ]

        sendPayload(DiscordGatewayPayload(code: .voice(.selectProtocol), payload: .object(payloadData)))
        startHeartbeat(seconds: heartbeatInterval / 1000)
        connected = true

        do {
            if source == nil {
                try getNewSource()
            } else {
                createTimer()
                readData()
            }
        } catch let err {
            self.error(message: "Failed creating encoder \(err)")
            self.disconnect()
        }

        DefaultDiscordLogger.Logger.debug("VoiceEngine is ready!", type: DiscordVoiceEngine.logType)

        guard config.captureVoice else { return }

        readSocket()
    }

    ///
    /// Sends raw PCM data to the encoder async.
    ///
    /// - parameter data: The data to write to the encoder.
    ///
    public func send(_ data: Data, doneHandler: (() -> ())? = nil) {
        // TODO Figure out this
//        writeQueue.async {[weak self] in
//            self?.encoder.write(data, doneHandler: doneHandler)
//        }
    }

    ///
    /// Sends a voice heartbeat to Discord. You shouldn't need to call this directly.
    ///
    public func sendHeartbeat() {
        guard !closed else { return }

        sendPayload(DiscordGatewayPayload(code: .voice(.heartbeat), payload: .integer(currentUnixTime)))

        let time = DispatchTime.now() + Double(heartbeatInterval)

        heartbeatQueue.asyncAfter(deadline: time) {[weak self] in self?.sendHeartbeat() }
    }

    private func sendSilence() {
        for _ in 0..<5 {
            sendVoiceData([0xF8, 0xFF, 0xFE])
            audioSleep()
        }

        sendSpeaking(false)
        udpQueueWrite.async { self.audioCount = -1 }
    }

    ///
    /// Sends whether we are speaking or not.
    ///
    /// - parameter speaking: Our speaking status.
    ///
    public func sendSpeaking(_ speaking: Bool) {
        let speakingObject: [String: Any] = [
            "speaking": speaking,
            "delay": 0
        ]

        sendPayload(DiscordGatewayPayload(code: .voice(.speaking), payload: .object(speakingObject)))
    }

    ///
    /// Sends Opus encoded voice data to Discord.
    ///
    /// **This should be called on the udpWriteQueue**.
    ///
    /// - parameter data: An Opus encoded packet.
    ///
    public func sendVoiceData(_ data: [UInt8]) {
        guard let udpSocket = self.udpSocket, secret != nil else { return }

        DefaultDiscordLogger.Logger.debug("Should send voice data: \(data.count) bytes",
                                          type: DiscordVoiceEngine.logType)

        do {
            try udpSocket.sendto(data: createVoicePacket(data))
        } catch DiscordVoiceEngineError.encryptionError {
            error(message: "Error encyrpting packet")
        } catch let err {
            error(message: "Failed sending voice packet \(err)")
            disconnect()

            return
        }

        sequenceNum = sequenceNum &+ 1
        timestamp = timestamp &+ UInt32(source.frameSize)
    }

    #if !os(iOS)
    ///
    /// Takes a process that outputs random audio data, and sends it to a hidden FFmpeg process that turns the data
    /// into raw PCM.
    ///
    /// Example setting up youtube-dl to play music.
    ///
    /// ```swift
    /// youtube = EncoderProcess()
    /// youtube.launchPath = "usrlocalbinyoutube-dl"
    /// youtube.arguments = ["-f", "bestaudio", "-q", "-o", "-", link]
    ///
    /// voiceEngine.setupMiddleware(youtube) {
    ///     print("youtube died")
    /// }
    /// ```
    ///
    /// - parameter middleware: The process that will output audio data.
    /// - parameter terminationHandler: Called when the middleware is done. Does not mean that all encoding is done.
    ///
    public func setupMiddleware(_ middleware: Process, terminationHandler: (() -> ())?) {
        DefaultDiscordLogger.Logger.debug("Setting up middleware", type: DiscordVoiceEngine.logType)

        // TODO this is bad, fix the types here
        guard let encoder = self.source as? DiscordBufferedVoiceDataSource else { return }

        encoder.middleware = DiscordEncoderMiddleware(encoder: encoder,
                                                      middleware: middleware,
                                                      terminationHandler: terminationHandler)
        encoder.middleware?.start()
    }
    #endif

    ///
    /// Starts the handshake with the Discord voice server. You shouldn't need to call this directly.
    ///
    public func startHandshake() {
        guard voiceDelegate != nil else { return }

        DefaultDiscordLogger.Logger.log("Starting voice handshake", type: DiscordVoiceEngine.logType)

        sendPayload(DiscordGatewayPayload(code: .voice(.identify), payload: .object(handshakeObject)))
    }

    ///
    /// Starts the engine's heartbeat. You should call this method when you know the interval that Discord expects.
    ///
    /// - parameter seconds: The heartbeat interval
    ///
    public func startHeartbeat(seconds: Int) {
        heartbeatInterval = seconds

        sendHeartbeat()
    }

    private func startUDP() {
        guard udpPort != -1 else { return }

        let base = voiceServerInformation.endpoint.components(separatedBy: ":")[0]
        let udpEndpoint = InternetAddress(hostname: base, port: UInt16(udpPort))

        DefaultDiscordLogger.Logger.debug("Starting voice UDP connection", type: DiscordVoiceEngine.logType)

        guard let client = try? UDPInternetSocket(address: udpEndpoint) else {
            disconnect()

            return
        }

        udpSocket = client

        // Begin async UDP setup
        findIP()
    }
}
