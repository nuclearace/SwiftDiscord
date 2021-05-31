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

import COPUS
import Foundation

/// Declares that a type will be a voice engine.
public protocol DiscordVoiceEngineSpec : DiscordWebSocketable, DiscordGatewayable, DiscordRunLoopable {
    // MARK: Properties

    /// The encoder for this engine. The encoder is responsible for turning raw audio data into OPUS encoded data.
    var source: DiscordVoiceDataSource? { get }

    /// The secret key used for encryption.
    var secret: [UInt8]! { get }

    // MARK: Methods

    ///
    /// Stops encoding and requests a new encoder. A `voiceEngine.ready` event will be fired when the encoder is ready.
    ///
    func requestNewDataSource()

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
    func setupMiddleware(_ middleware: Process, terminationHandler: (() -> ())?)
    #endif
}

/// Declares that a type will be a client for a voice engine.
public protocol DiscordVoiceEngineDelegate : AnyObject {
    // MARK: Methods

    ///
    /// Handles received opus voice data from a voice engine.
    ///
    /// - parameter data: The voice data that was received
    ///
    func voiceEngine(_ engine: DiscordVoiceEngine, didReceiveOpusVoiceData data: DiscordOpusVoiceData)

    ///
    /// Handles received raw voice data from a voice engine.
    ///
    /// - parameter data: The voice data that was received
    ///
    func voiceEngine(_ engine: DiscordVoiceEngine, didReceiveRawVoiceData data: DiscordRawVoiceData)

    ///
    /// Called when the voice engine disconnects.
    ///
    /// - parameter engine: The engine that disconnected.
    ///
    func voiceEngineDidDisconnect(_ engine: DiscordVoiceEngine)

    ///
    /// Called when the voice engine needs an encoder.
    ///
    /// - parameter engine: The engine that needs an encoder.
    /// - returns: An encoder.
    ///
    func voiceEngineNeedsDataSource(_ engine: DiscordVoiceEngine) throws -> DiscordVoiceDataSource?

    ///
    /// Called when the voice engine is ready.
    ///
    /// - parameter engine: The engine that's ready.
    ///
    func voiceEngineReady(_ engine: DiscordVoiceEngine)
}

/// Represents an error that can occur during voice operations.
public enum DiscordVoiceError : Error {
    /// Thrown when a failure occurs creating an encoder.
    case creationFail

    /// Thrown when a failure occurs encoding.
    case encodeFail

    /// Thrown when a decode failure occurs.
    case decodeFail

    /// Thrown when the first packet is received.
    case initialPacket
}

/// A struct that is used to configure the high-level functions of a VoiceEngine
public struct DiscordVoiceEngineConfiguration {
    /// Whether or not this engine should capture voice.
    public var captureVoice: Bool

    /// Whether or not this engine should try and decode incoming voice into raw PCM.
    public var decodeVoice: Bool

    ///
    /// Default configuration:
    ///     captureVoice = true
    ///     decodeVoice = false
    ///
    public init() {
        captureVoice = true
        decodeVoice = false
    }

    ///
    /// Creates a new configuration with the specified options.
    ///
    public init(captureVoice: Bool, decodeVoice: Bool) {
        self.captureVoice = captureVoice
        self.decodeVoice = decodeVoice
    }
}
