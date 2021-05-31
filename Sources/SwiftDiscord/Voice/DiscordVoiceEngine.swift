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
import Logging
import WebSocketKit
import Socket
import Sodium

fileprivate let logger = Logger(label: "DiscordVoiceEngine")

///
/// A subclass of `DiscordEngine` that provides functionality for voice communication.
///
/// Discord uses encrypted OPUS encoded voice packets. The engine is responsible for encyrptingdecrypting voice
/// packets that are sent and received.
///
public final class DiscordVoiceEngine : DiscordVoiceEngineSpec {
    enum EngineError : Error {
        case decryptionError
        case encryptionError
        case ipExtraction
        case unknown
    }

    // MARK: Properties

    private static let padding = [UInt8](repeating: 0x00, count: 12)

    /// The configuration for this engine.
    public let config: DiscordVoiceEngineConfiguration

    /// The heartbeat queue.
    public let heartbeatQueue = DispatchQueue(label: "discordVoiceEngine.heartbeatQueue")

    /// The parse queue.
    public let parseQueue = DispatchQueue(label: "discordVoiceEngine.parseQueue")

    /// The run loop for this shard.
    public let runloop: EventLoop

    /// The voice url
    public var connectURL: String {
        return "wss://\(voiceServerInformation.endpoint.components(separatedBy: ":")[0])?v=4"
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
    public private(set) var source: DiscordVoiceDataSource?

    /// The modes that are available for communication. Only xsalsa20_poly1305 is supported currently
    public private(set) var modes = [String]()

    /// The secret key used for encryption
    public private(set) var secret: [UInt8]!

    /// Our SSRC
    public private(set) var ssrc: UInt32 = 0

    /// The UDP socket that is used to send/receive voice data
    public private(set) var udpSocket: Socket?

    // Server UDP ip
    public private(set) var udpIp = ""

    /// Server UDP port
    public private(set) var udpPort = -1

    /// Information about the voice server we are connected to
    public private(set) var voiceServerInformation: DiscordVoiceServerInformation!

    /// The voice state for this engine.
    public private(set) var voiceState: DiscordVoiceState!

    private let decoderSession = DiscordVoiceSessionDecoder()
    private let sendTimer: DispatchSourceTimer
    private let udpQueueWrite = DispatchQueue(label: "discordVoiceEngine.udpQueueWrite")
    private let udpQueueRead = DispatchQueue(label: "discordVoiceEngine.udpQueueRead")

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

    private var speaking = false

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
                onLoop: EventLoop,
                config: DiscordVoiceEngineConfiguration,
                voiceServerInformation: DiscordVoiceServerInformation,
                voiceState: DiscordVoiceState,
                source: DiscordVoiceDataSource?,
                secret: [UInt8]?) {
        self.voiceDelegate = delegate
        self.runloop = onLoop
        self.config = config

        _ = sodium_init()

        signal(SIGPIPE, SIG_IGN)

        self.voiceState = voiceState
        self.voiceServerInformation = voiceServerInformation
        self.source = source
        self.secret = secret
        self.sendTimer = DispatchSource.makeTimerSource(flags: .strict, queue: udpQueueWrite)

        configureTimer()
    }

    deinit {
        logger.debug("deinit")

        closeOutEngine()
    }

    // MARK: Methods

    private func closeOutEngine() {
        guard !closed else { return }

        udpSocket?.close()
        closed = true
        connected = false
        sendTimer.cancel()
    }

    private func configureTimer() {
        self.sendTimer.setEventHandler {[weak self] in
            guard let this = self else { return }

            this.getVoiceData()
        }

        self.sendTimer.schedule(wallDeadline: .now(), repeating: .milliseconds(20))

        // TODO this is wasteful, figure out if there's a smart way to start and stop the timer.
        // Maybe let the user decide?
        sendTimer.resume()
    }

    private func createRTPHeader() -> [UInt8] {
        let header = UnsafeMutableRawBufferPointer.allocate(byteCount: 12, alignment: MemoryLayout<Int>.alignment)

        defer { header.deallocate() }

        header.storeBytes(of: 0x80, as: UInt8.self)
        header.storeBytes(of: 0x78, toByteOffset: 1, as: UInt8.self)
        header.storeBytes(of: sequenceNum.bigEndian, toByteOffset: 2, as: UInt16.self)
        header.storeBytes(of: timestamp.bigEndian, toByteOffset: 4, as: UInt32.self)
        header.storeBytes(of: ssrc.bigEndian, toByteOffset: 8, as: UInt32.self)

        return Array(header)
    }

    private func createVoicePacket(_ data: [UInt8]) throws -> [UInt8] {
        let packetSize = Int(crypto_secretbox_MACBYTES) + data.count
        let encrypted = UnsafeMutablePointer<UInt8>.allocate(capacity: packetSize)
        let rtpHeader = createRTPHeader()
        let nonce = rtpHeader + DiscordVoiceEngine.padding
        let buf = data

        defer { encrypted.deallocate() }

        let success = crypto_secretbox_easy(encrypted, buf, UInt64(buf.count), nonce, secret)

        guard success != -1 else { throw EngineError.encryptionError }

        return rtpHeader + Array(UnsafeBufferPointer(start: encrypted, count: packetSize))
    }

    private func decryptVoiceData(_ data: Data) throws -> [UInt8] {
        // TODO this isn't totally correct, there might be an extension after the rtp header
        let rtpHeader = Array(data.prefix(12))
        let voiceData = Array(data.dropFirst(12))
        let audioSize = voiceData.count - Int(crypto_secretbox_MACBYTES)

        guard audioSize > 0 else { throw EngineError.decryptionError }

        let unencrypted = UnsafeMutablePointer<UInt8>.allocate(capacity: audioSize)
        let nonce = rtpHeader + DiscordVoiceEngine.padding

        defer { unencrypted.deallocate() }

        let success = crypto_secretbox_open_easy(unencrypted, voiceData, UInt64(data.count - 12), nonce, secret)

        guard success != -1 else { throw EngineError.decryptionError }

        return rtpHeader + Array(UnsafeBufferPointer(start: unencrypted, count: audioSize))
    }

    ///
    /// Disconnects the voice engine.
    ///
    public func disconnect() {
        logger.info("Disconnecting VoiceEngine")

        closeWebSockets()
        closeOutEngine()

        voiceDelegate?.voiceEngineDidDisconnect(self)
    }

    private func extractIPAndPort(from bytes: Data) throws -> (String, Int) {
        logger.debug("Extracting ip and port from \(bytes)")

        let ipData = bytes.dropLast(2)
        let portBytes = Array(bytes.suffix(from: bytes.endIndex.advanced(by: -2)))
        let port = (Int(portBytes[0]) | Int(portBytes[1])) << 8

        guard let ipString = String(data: ipData, encoding: .utf8)?.replacingOccurrences(of: "\0", with: "") else {
            throw EngineError.ipExtraction
        }

        return (ipString, port)
    }

    // https://discord.com/developers/docs/topics/voice-connections#ip-discovery
    private func findIP() {
        udpQueueWrite.async {
            guard let udpSocket = self.udpSocket else { return }

            let discoveryData = [UInt8](repeating: 0x00, count: 70)

            do {
                var data = Data()
                try udpSocket.write(from: Data(discoveryData))

                _ = try udpSocket.readDatagram(into: &data)
                let (ip, port) = try self.extractIPAndPort(from: data)

                self.selectProtocol(with: ip, on: port)
            } catch {
                self.error(message: "Something went wrong extracting the ip and port \(error)")
                self.disconnect()
            }
        }
    }

    private func getNewDataSource() {
        // Guard against trying to create multiple encoders at once
        udpQueueWrite.async {
            do {
                self.source = try self.voiceDelegate?.voiceEngineNeedsDataSource(self)

                self.readSource()

                self.voiceDelegate?.voiceEngineReady(self)
            } catch {
                self.error(message: "Something went wrong getting a new data source \(error)")
                self.disconnect()
            }
        }
    }

    private func getVoiceData() {
        guard let source = source else { return }

        do {
            sendVoiceData(try source.engineNeedsData(self))
        } catch DiscordVoiceDataSourceStatus.noData {
            logger.trace("No data")

            if speaking {
                sendSpeaking(false)
            }
        } catch DiscordVoiceDataSourceStatus.done {
            logger.debug("Voice source done, sending silence")

            sendSilence(previousSource: nil)
        } catch let DiscordVoiceDataSourceStatus.silenceDone(source) {
            logger.debug("Voice silence done, requesting new source")

            if speaking {
                sendSpeaking(false)
            }

            if source == nil {
                getNewDataSource()
            } else {
                // This silence had a source from a previous engine and we just finished sending the initial silence
                // re-add the old source for playback
                self.source = source
            }
        } catch {
            logger.error("Error getting voice data: \(error)")
        }
    }

    ///
    /// Handles a close from the WebSocket.
    ///
    /// - parameter reason: The reason the socket closed.
    ///
    public func handleClose(reason: Error? = nil) {
        logger.info("Voice engine closed")

        closeOutEngine()
    }

    /// Currently unused in VoiceEngines.
    public func handleDispatch(_ payload: DiscordGatewayPayload) { }

    ///
    /// Handles the hello event.
    ///
    /// - parameter payload: The dispatch payload
    ///
    public func handleHello(_ payload: DiscordGatewayPayload) {
        logger.debug("Handling hello \(payload)")

        guard case let .object(helloPayload) = payload.payload,
              let heartbeat = helloPayload["heartbeat_interval"] as? Int else {
            logger.error("Error extracting heartbeat info \(payload)")

            return
        }

        startHeartbeat(milliseconds: Int(Double(heartbeat) * 0.75))
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
            udpQueueWrite.sync {
                self.handleVoiceSessionDescription(with: payload.payload)
                self.sendSilence(previousSource: self.source)
            }
        case .speaking:
            logger.debug("Got speaking \(payload)")
        case .hello:
            handleHello(payload)
        case .heartbeatAck:
            logger.debug("Got heartbeat ack")
        case .resumed:
            handleResumed(payload)
        case .clientDisconnect:
            // Should we tell someone about this?
            logger.debug("Someone left voice channel \(payload)")
        default:
            logger.debug("Unhandled voice payload \(payload)")
        }
    }

    private func handleReady(with payload: DiscordGatewayPayloadData) {
        guard case let .object(voiceInformation) = payload,
              let ssrc = voiceInformation["ssrc"] as? Int,
              let udpPort = voiceInformation["port"] as? Int,
              let modes = voiceInformation["modes"] as? [String], 
              let ip = voiceInformation["ip"] as? String else {
            disconnect()

            return
        }

        self.udpPort = udpPort
        self.modes = modes
        self.ssrc = UInt32(ssrc)
        self.udpIp = ip

        startUDP()
    }

    ///
    /// Handles the resumed event.
    ///
    /// - parameter payload: The payload for the event.
    ///
    public func handleResumed(_ payload: DiscordGatewayPayload) {
        // TODO implement voice resume
        logger.debug("Should handle resumed \(payload)")
    }

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
            logger.info("Got unknown payload \(string)")

            return
        }

        handleGatewayPayload(decoded)
    }

    private func readSource() {
        source?.startReading()
    }

    private func readSocket() {
        // TODO refactor to be non-blocking
        udpQueueRead.async {[weak self] in
            guard let socket = self?.udpSocket, self?.connected ?? false else { return }

            do {
                var data = Data()

                _ = try socket.readDatagram(into: &data)

                logger.debug("Received data \(data)")

                guard let this = self else { return }

                let packet = DiscordOpusVoiceData(voicePacket: try this.decryptVoiceData(data))

                if this.config.decodeVoice {
                    this.voiceDelegate?.voiceEngine(this,
                                                    didReceiveRawVoiceData: try this.decoderSession.decode(packet))
                } else {
                    this.voiceDelegate?.voiceEngine(this, didReceiveOpusVoiceData: packet)
                }
            } catch DiscordVoiceError.initialPacket {
                logger.debug("Got initial packet")
            } catch DiscordVoiceError.decodeFail {
                logger.debug("Failed to decode a packet")
            } catch EngineError.decryptionError {
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
    public func requestNewDataSource() {
        getNewDataSource()
    }

    // Tells the voice websocket what our ip and port is, and what encryption mode we will use
    // currently only xsalsa20_poly1305 is supported
    // After this point we are good to go in sending encrypted voice packets
    private func selectProtocol(with ip: String, on port: Int) {
        logger.debug("Selecting UDP protocol with ip: \(ip) on port: \(port)")

        let payloadData: [String: Any] = [
            "protocol": "udp",
            "data": [
                "address": ip,
                "port": port,
                "mode": "xsalsa20_poly1305"
            ]
        ]

        sendPayload(DiscordGatewayPayload(code: .voice(.selectProtocol), payload: .object(payloadData)))
        connected = true

        // No need to get ask for a source, we send silence before we get this step,
        // which will cause an ask for a new source
        readSource()

        logger.debug("VoiceEngine is ready!")

        guard config.captureVoice else { return }

        readSocket()
    }

    ///
    /// Sends a voice heartbeat to Discord. You shouldn't need to call this directly.
    ///
    public func sendHeartbeat() {
        guard !closed else { return }

        sendPayload(DiscordGatewayPayload(code: .voice(.heartbeat), payload: .integer(currentUnixTime)))

        let time = DispatchTime.now() + .milliseconds(heartbeatInterval)

        heartbeatQueue.asyncAfter(deadline: time) {[weak self] in self?.sendHeartbeat() }
    }

    /// Only call between new data source requests, assumes inside the udpWriteQueue.
    private func sendSilence(previousSource: DiscordVoiceDataSource?) {
        source = DiscordSilenceVoiceDataSource(previousSource: previousSource)
    }

    ///
    /// Sends whether we are speaking or not.
    ///
    /// - parameter speaking: Our speaking status.
    ///
    private func sendSpeaking(_ speaking: Bool) {
        self.speaking = speaking

        let speakingObject: [String: Any] = [
            "speaking": 1 << 1,
            "delay": 0,
            "ssrc": ssrc
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
    private func sendVoiceData(_ data: [UInt8]) {
        guard let udpSocket = self.udpSocket, let frameSize = source?.frameSize, secret != nil else { return }

        if !speaking {
            sendSpeaking(true)
        }

        logger.trace("Should send voice data: \(data.count) bytes")

        do {
            try udpSocket.write(from: Data(createVoicePacket(data)))
        } catch EngineError.encryptionError {
            error(message: "Error encrypting packet")
        } catch let err {
            error(message: "Failed sending voice packet \(err)")
            disconnect()

            return
        }

        sequenceNum = sequenceNum &+ 1
        timestamp = timestamp &+ UInt32(frameSize)
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
    /// **Currently only works if using the default `DiscordBufferedVoiceDataSource`**
    ///
    /// - parameter middleware: The process that will output audio data.
    /// - parameter terminationHandler: Called when the middleware is done. Does not mean that all encoding is done.
    ///
    public func setupMiddleware(_ middleware: Process, terminationHandler: (() -> ())?) {
        logger.debug("Setting up middleware")

        // TODO this is bad, fix the types here
        guard let source = self.source as? DiscordBufferedVoiceDataSource else { return }

        source.middleware = DiscordEncoderMiddleware(source: source,
                                                     middleware: middleware,
                                                     terminationHandler: terminationHandler)
        do {
            try source.middleware?.start()
        } catch {
            logger.error("Could not start middleware: \(error)")
        }
    }
    #endif

    ///
    /// Starts the handshake with the Discord voice server. You shouldn't need to call this directly.
    ///
    public func startHandshake() {
        guard voiceDelegate != nil else { return }

        logger.info("Starting voice handshake")

        sendPayload(DiscordGatewayPayload(code: .voice(.identify), payload: .object(handshakeObject)))
    }

    ///
    /// Starts the engine's heartbeat. You should call this method when you know the interval that Discord expects.
    ///
    /// - parameter milliseconds: The heartbeat interval
    ///
    public func startHeartbeat(milliseconds: Int) {
        heartbeatInterval = milliseconds

        sendHeartbeat()
    }

    private func startUDP() {
        guard udpPort != -1, !udpIp.isEmpty else { return }

        logger.debug("Starting voice UDP connection")

        do {
            guard let sig = try Socket.Signature(
                    protocolFamily: .inet,
                    socketType: .datagram,
                    proto: .udp,
                    hostname: "\(udpIp)",
                    port: Int32(udpPort)
            ) else {
                throw EngineError.unknown
            }

            udpSocket = try Socket.create(connectedUsing: sig)

            // Begin async UDP setup
            findIP()
        } catch let err {
            // TODO Handle voice error disconnect from voice
            logger.error("UDP setup error \(err)")
        }
    }
}
