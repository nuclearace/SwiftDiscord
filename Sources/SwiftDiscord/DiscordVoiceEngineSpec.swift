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

/// Declares that a type will be a voice engine.
public protocol DiscordVoiceEngineSpec : DiscordEngineSpec {
    // MARK: Properties

    /// The encoder for this engine. The encoder is responsible for turning raw audio data into OPUS encoded data.
    var encoder: DiscordVoiceEncoder? { get }

    /// The secret key used for encryption.
    var secret: [UInt8]! { get }

    // MARK: Methods

    /**
        Used to request a new `FileHandle` that can be used to write directly to the encoder. Which will in turn be
        sent to Discord.

        Example using youtube-dl to play music:

        ```swift
        youtube = EncoderProcess()
        youtube.launchPath = "/usr/local/bin/youtube-dl"
        youtube.arguments = ["-f", "bestaudio", "-q", "-o", "-", link]
        youtube.standardOutput = client.voiceEngines[guildId]?.requestFileHandleForWriting()

        youtube.terminationHandler = {[weak encoder = voiceEngine.encoder!] process in
            encoder?.finishEncodingAndClose()
        }

        youtube.launch()
        ```

        - returns: An optional containing a FileHandle that can be written to, or nil if there is no encoder.
    */
    func requestFileHandleForWriting() -> FileHandle?

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

    /**
        Tells Discord that we are starting to speak.
    */
    func startSpeaking()

    /**
        Tells Discord we're done speaking.
    */
    func stopSpeaking()
}

public extension DiscordVoiceEngineSpec {
    /// Default implementation.
    public func send(_ data: Data, doneHandler: (() -> Void)? = nil) {
        encoder?.write(data, doneHandler: doneHandler)
    }
}
