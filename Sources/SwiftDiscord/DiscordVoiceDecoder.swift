// The MIT License (MIT)
// Copyright (c) 2017 Erik Little

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
import DiscordOpus
import Foundation

open class DiscordVoiceSessionDecoder {
    open func decode(_ packet: [UInt8]) throws -> DiscordVoiceData {
        let rtpHeader = Array(packet.prefix(12)).map(Int.init(_:))
        let voiceData = Array(packet.dropFirst(12))
        let seqNum = rtpHeader[2] << 8 | rtpHeader[3]
        let timestamp = rtpHeader[4] << 24 | rtpHeader[5] << 16 | rtpHeader[6] << 8 | rtpHeader[7]
        let ssrc = rtpHeader[8] << 24 | rtpHeader[9] << 16 | rtpHeader[10] << 8 | rtpHeader[11]

        // TODO Decoding opus

        return DiscordVoiceData(seqNum: seqNum, timestamp: timestamp, ssrc: ssrc, voiceData: voiceData)
    }
}

/**
    An Opus decoder.

    Takes Opus packets and returns raw PCM 16-bit-le/sample data.
*/
open class DiscordOpusDecoder : DiscordOpusCodeable {
    // MARK: Properties

    /// The number of channels.
    public let channels: Int

    /// The sampling rate.
    public let sampleRate: Int

    private let decoderState: OpaquePointer

    // MARK: Initializers

    /**
        Creates a Decoder that takes Opus encoded data and outputs raw PCM 16-bit-le/sample data.

        - parameter sampleRate: The sample rate for the decoder. Discord expects this to be 48k.
        - parameter channels: The number of channels in the stream to decode, should always be 2.
        - parameter gain: The gain for this decoder.
    */
    public init(sampleRate: Int, channels: Int, gain: Int = 0) throws {
        self.sampleRate = sampleRate
        self.channels = channels

        var err = 0 as Int32

        decoderState = opus_decoder_create(Int32(sampleRate), Int32(channels), &err)
        err = configure_decoder(decoderState, Int32(gain))

        guard err == 0 else {
            destroyState()

            throw DiscordVoiceError.creationFail
        }
    }

    deinit {
        destroyState()
    }

    // MARK: Methods

    private func destroyState() {
        opus_decoder_destroy(decoderState)
    }

    /**
        Decodes Opus data into raw PCM 16-bit-le/sample data.

        - parameter audio: A pointer to the audio data.
        - parameter packetSize: The number of bytes in this packet.
        - parameter frameSize: The size of the frame in samples per channel.
        - returns: An opus encoded packet.
    */
    open func decode(_ audio: UnsafePointer<UInt8>?, packetSize: Int, frameSize: Int) throws -> [opus_int16] {
        let output: UnsafeMutablePointer<opus_int16>

        defer { free(output) }

        let maxSize = maxFrameSize(assumingSize: frameSize)
        output = UnsafeMutablePointer<opus_int16>.allocate(capacity: maxSize)
        let decodedSize = Int(opus_decode(decoderState, audio, Int32(packetSize), output, Int32(maxSize), 0))
        let totalSize = decodedSize * channels

        guard audio != nil, decodedSize > 0, totalSize <= maxSize else { throw DiscordVoiceError.decodeFail }

        return Array(UnsafeBufferPointer(start: output, count: totalSize))
    }
}

/// A struct that contains a Discord voice packet. The voice data is still opus encoded.
public struct DiscordVoiceData {
    /// The sequence number of this packet.
    public let seqNum: Int

    /// The source of this packet.
    public let ssrc: Int

    /// The timestamp of this packet.
    public let timestamp: Int

    /// The raw voice data.
    public let voiceData: [UInt8]

    init(seqNum: Int, timestamp: Int, ssrc: Int, voiceData: [UInt8]) {
        self.seqNum = seqNum
        self.timestamp = timestamp
        self.ssrc = ssrc
        self.voiceData = voiceData
    }
}
