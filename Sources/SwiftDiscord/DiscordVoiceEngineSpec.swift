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
public protocol DiscordVoiceEngineSpec : DiscordEngineSpec {
    // MARK: Properties

    /// The encoder for this engine. The encoder is responsible for turning raw audio data into OPUS encoded data.
    var encoder: DiscordVoiceEncoder! { get }

    /// The secret key used for encryption.
    var secret: [UInt8]! { get }

    // MARK: Methods

    /**
        Stops encoding and requests a new encoder. A `voiceEngine.ready` event will be fired when the encoder is ready.
    */
    func requestNewEncoder() throws

    /**
        An async write to the encoder.

        - parameter data: Raw audio data that should be turned into OPUS encoded data.
        - parameter doneHandler: An optional handler that will be called when we are done writing.
    */
    func send(_ data: Data, doneHandler: (() -> Void)?)

    /**
        Sends OPUS encoded voice data to Discord.

        - parameter data: An array of OPUS encoded voice data.
    */
    func sendVoiceData(_ data: [UInt8])

    #if !os(iOS)
    /**
        Takes a process that outputs random audio data, and sends it to a hidden FFmpeg process that turns the data
        into raw PCM.

        Example setting up youtube-dl to play music.

        ```swift
        youtube = EncoderProcess()
        youtube.launchPath = "/usr/local/bin/youtube-dl"
        youtube.arguments = ["-f", "bestaudio", "-q", "-o", "-", link]

        voiceEngine.setupMiddleware(youtube) {
            print("youtube died")
        }
        ```

        - parameter middleware: The process that will output audio data.
        - parameter terminationHandler: Called when the middleware is done. Does not mean that all encoding is done.
    */
    func setupMiddleware(_ middleware: EncoderProcess, terminationHandler: (() -> Void)?)
    #endif

    /**
        Tells Discord that we are starting to speak.
    */
    func startSpeaking()

    /**
        Tells Discord we're done speaking.
    */
    func stopSpeaking()
}

/// Declares that a type has enough information to encode/decode Opus data.
public protocol DiscordOpusCodeable {
    // MARK: Properties

    /// The number of channels.
    var channels: Int { get }

    /// The sampling rate.
    var sampleRate: Int { get }

    // MARK: Methods

    /**
        Returns the maximum number of bytes that a frame can contain given a
        frame size in number of samples per channel.

        - parameter assumingSize: The size of the frame, in number of samples per channel.
        - returns: The number of bytes in this frame.
    */
    func maxFrameSize(assumingSize size: Int) -> Int
}

public extension DiscordOpusCodeable {
    /**
        Returns the maximum number of bytes that a frame can contain given a
        frame size in number of samples per channel.

        - parameter assumingSize: The size of the frame, in number of samples per channel.
        - returns: The number of bytes in this frame.
    */
    public func maxFrameSize(assumingSize size: Int) -> Int {
        return size * channels * MemoryLayout<opus_int16>.size
    }
}
