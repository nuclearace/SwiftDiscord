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

import Foundation
import Dispatch
#if !os(Linux)
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
        return "wss://" + voiceServerInformation.endpoint.components(separatedBy: ":")[0]
    }

    /// The type of `DiscordEngine` this is. Used to correctly fire engine events.
    public override var engineType: String {
        return "voiceEngine"
    }

    /// The id of the guild this voice engine is for.
    public var guildId: String {
        return voiceState.guildId
    }

    /// Creates the handshake object that Discord expects.
    public override var handshakeObject: [String: Any] {
        return [
            "session_id": voiceState.sessionId,
            "server_id": voiceState.guildId,
            "user_id": client!.user!.id,
            "token": voiceServerInformation.token
        ]
    }

    /// The encoder for this engine. The encoder is responsible for turning raw audio data into OPUS encoded data
    public private(set) var encoder: DiscordVoiceEncoder?

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
    public private(set) var voiceServerInformation: DiscordVoiceServerInformation!

    /// The voice state for this engine.
    public private(set) var voiceState: DiscordVoiceState!

    override var logType: String {
        return "DiscordVoiceEngine"
    }

    private let encoderSemaphore = DispatchSemaphore(value: 1)
    private let padding = [UInt8](repeating: 0x00, count: 12)
    private let udpQueue = DispatchQueue(label: "discordVoiceEngine.udpQueue")
    private let udpQueueRead = DispatchQueue(label: "discordVoiceEngine.udpQueueRead")

    private var audioCount = -1
    private var currentUnixTime: Int {
        return Int(Date().timeIntervalSince1970 * 1000)
    }

    private var closed = false

    #if !os(Linux)
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
    public convenience init(client: DiscordClientSpec,
                            voiceServerInformation: DiscordVoiceServerInformation,
                            voiceState: DiscordVoiceState,
                            encoder: DiscordVoiceEncoder?,
                            secret: [UInt8]?) {
        self.init(client: client)

        _ = sodium_init()

        signal(SIGPIPE, SIG_IGN)

        self.voiceState = voiceState
        self.voiceServerInformation = voiceServerInformation
        self.encoder = encoder
        self.secret = secret
    }

    deinit {
        DefaultDiscordLogger.Logger.debug("deinit", type: logType)

        closeOutEngine()
    }

    // MARK: Methods

    private func audioSleep() {
        guard audioCount != -1 else {
            // First time
            startSpeaking() // Make sure we're speaking
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

        DefaultDiscordLogger.Logger.debug("Sleeping %@ %@", type: logType, args: waitTime, audioCount)

        Thread.sleep(forTimeInterval: waitTime)

        audioCount += 1
    }

    private func createEncoder() throws {
        // Guard against trying to create multiple encoders at once
        encoderSemaphore.wait()
        // This will trigger a block while the old encoder is released and cleans itself up
        // It's important that we first set it to nil, otherwise the new encoder will exist at the same time as the old
        // one. Which causes weirdness
        encoder = nil
        encoder = try client?.voiceEngineNeedsEncoder(self)

        readData()

        client?.voiceEngineReady(self)

        encoderSemaphore.signal()
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

    private func closeOutEngine() {
        super.disconnect()

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

        let packetSize = Int(crypto_secretbox_MACBYTES) + data.count
        let encrypted = UnsafeMutablePointer<UInt8>.allocate(capacity: packetSize)
        let rtpHeader = createRTPHeader()
        var nonce = rtpHeader + padding
        var buf = data

        let success = crypto_secretbox_easy(encrypted, &buf, UInt64(buf.count), &nonce, &secret!)

        guard success != -1 else { throw DiscordVoiceEngineError.encryptionError }

        return rtpHeader + Array(UnsafeBufferPointer(start: encrypted, count: packetSize))
    }

    private func decryptVoiceData(_ data: Data) throws -> DiscordVoiceData {
        defer { free(unencrypted) }

        let rtpHeader = Array(data.prefix(12))
        let voiceData = Array(data.dropFirst(12))
        let audioSize = voiceData.count - Int(crypto_secretbox_MACBYTES)
        let unencrypted = UnsafeMutablePointer<UInt8>.allocate(capacity: audioSize)
        var nonce = rtpHeader + padding

        let success = crypto_secretbox_open_easy(unencrypted, voiceData, UInt64(data.count - 12), &nonce, &secret!)

        guard success != -1 else { throw DiscordVoiceEngineError.decryptionError }

        return DiscordVoiceData(rtpHeader: rtpHeader,
            voiceData: Array(UnsafeBufferPointer(start: unencrypted, count: audioSize)))
    }

    /**
        Disconnects the voice engine.
    */
    public override func disconnect() {
        DefaultDiscordLogger.Logger.log("Disconnecting VoiceEngine", type: logType)

        client?.voiceEngineDidDisconnect(self)
        closeOutEngine()
    }

    private func extractIPAndPort(from bytes: [UInt8]) throws -> (String, Int) {
        DefaultDiscordLogger.Logger.debug("Extracting ip and port from %@", type: logType, args: bytes)

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
        do {
            try createEncoder()
        } catch let err {
            error(message: "Failed creating new encoder \(err)")
            disconnect()
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
        case .speaking:
            DefaultDiscordLogger.Logger.debug("Got speaking", type: logType, args: payload)
        default:
            DefaultDiscordLogger.Logger.debug("Unhandled voice payload %@", type: logType, args: payload)
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

    private func handleVoiceSessionDescription(with payload: DiscordGatewayPayloadData) {
        guard case let .object(voiceInformation) = payload,
                let secret = voiceInformation["secret_key"] as? [Int] else {
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

    private func readData() {
        encoder?.read {[weak self] done, data in
            guard let this = self, this.connected else { return } // engine died
            guard !done else {
                DefaultDiscordLogger.Logger.debug("No data, reader probably closed", type: this.logType)

                this.sendSpeaking(false)
                this.handleDoneReading()

                return
            }

            DefaultDiscordLogger.Logger.debug("Read %@ bytes", type: this.logType, args: data.count)

            this.sendVoiceData(data)
            this.readData()
        }
    }

    private func readSocket() {
        udpQueueRead.async {[weak self] in
            guard let socket = self?.udpSocket, self?.connected ?? false else { return }

            do {
                let (data, _) = try socket.receive(maxBytes: 4096)
                guard let voiceData = try self?.decryptVoiceData(Data(bytes: data)) else {
                    return
                }

                self?.client?.handleVoiceData(voiceData)
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

    /**
        Used to request a new `FileHandle` that can be used to write directly to the encoder. Which will in turn be
        sent to Discord.

        Example using youtube-dl to play music:

        ```swift
        guard let voiceEngine = client.voiceEngines[guildId] else { return }
        youtube = EncoderProcess()
        youtube.launchPath = "/usr/local/bin/youtube-dl"
        youtube.arguments = ["-f", "bestaudio", "-q", "-o", "-", link]
        youtube.standardOutput = voiceEngine.requestFileHandleForWriting()

        youtube.terminationHandler = {[weak encoder = voiceEngine.encoder!] process in
            encoder?.finishEncodingAndClose()
        }

        youtube.launch()
        ```

        - returns: An optional containing a FileHandle that can be written to, or nil if there is no encoder.
    */
    public func requestFileHandleForWriting() -> FileHandle? {
        return encoder?.writeToHandler
    }

    /**
        Stops encoding and requests a new encoder. The `isReadyToSendVoiceWithEngine` delegate method is called when
        the new encoder is ready.
    */
    public func requestNewEncoder() throws {
        try createEncoder()
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

        do {
            if encoder == nil {
                try createEncoder()
            } else {
                readData()
            }
        } catch let err {
            self.error(message: "Failed creating encoder \(err)")
            self.disconnect()
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

    private func sendSpeaking(_ speaking: Bool) {
        let speakingObject: [String: Any] = [
            "speaking": speaking,
            "delay": 0
        ]

        sendGatewayPayload(DiscordGatewayPayload(code: .voice(.speaking), payload: .object(speakingObject)))
    }

    /**
        Sends Opus encoded voice data to Discord.

        - parameter data: An Opus encoded packet.
    */
    public func sendVoiceData(_ data: [UInt8]) {
        udpQueue.sync {
            guard let udpSocket = self.udpSocket else { return }

            DefaultDiscordLogger.Logger.debug("Should send voice data: %@ bytes", type: self.logType, args: data.count)

            do {
                try udpSocket.send(bytes: self.createVoicePacket(data))
            } catch DiscordVoiceEngineError.encryptionError {
                self.error(message: "Error encyrpting packet")
            } catch let err {
                self.error(message: "Failed sending voice packet \(err)")
                self.disconnect()

                return
            }

            self.sequenceNum = self.sequenceNum &+ 1
            self.timestamp = self.timestamp &+ 960
        }

        audioSleep()
    }

    /**
        Starts the handshake with the Discord voice server. You shouldn't need to call this directly.
    */
    public override func startHandshake() {
        guard client != nil else { return }

        DefaultDiscordLogger.Logger.log("Starting voice handshake", type: logType)

        sendGatewayPayload(DiscordGatewayPayload(code: .voice(.identify), payload: .object(handshakeObject)))
    }

    /**
        Tells Discord that we are speaking.

        This should be balenced with a call to stopSpeaking()
    */
    public func startSpeaking() {
        sendSpeaking(true)
    }

    private func startUDP() {
        guard udpPort != -1 else { return }

        let base = voiceServerInformation.endpoint.components(separatedBy: ":")[0]
        let udpEndpoint = InternetAddress(hostname: base, port: UInt16(udpPort))

        guard let client = try? UDPClient(address: udpEndpoint) else {
            disconnect()

            return
        }

        udpSocket = client

        // Begin async UDP setup
        findIP()
    }

    /**
        Tells Discord we're done speaking.
    */
    public func stopSpeaking() {
        sendSpeaking(false)
    }
}
