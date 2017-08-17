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

/// Class that decodes Opus voice data into raw PCM data for a VoiceEngine. It can decode multiple streams. Decoding is
/// not thread safe, and it is up to the caller to decode safely.
open class DiscordVoiceSessionDecoder {
    private var decoders = [Int: DiscordOpusDecoder]()
    private var sequences = [Int: Int]()
    private var timestamps = [Int: Int]()

    // MARK: Methods

    ///
    /// Decodes an opus encoded packet into raw PCM. The first 12 bytes of the packet should be the RTP header.
    ///
    /// - parameter packet: The full voice packet, including RTP header.
    /// - returns: A `DiscordVoiceData`.
    ///
    open func decode(_ packet: DiscordOpusVoiceData) throws -> DiscordRawVoiceData {
        let decoder: DiscordOpusDecoder

        if let previous = decoders[packet.ssrc] {
            DefaultDiscordLogger.Logger.debug("Reusing decoder for ssrc: \(packet.ssrc), seqNum: \(packet.seqNum), timestamp: \(packet.timestamp)", type: "DiscordVoiceSessionDecoder")
            decoder = previous
        } else {
            DefaultDiscordLogger.Logger.debug("New decoder for ssrc: \(packet.ssrc), seqNum: \(packet.seqNum), timestamp: \(packet.timestamp)", type: "DiscordVoiceSessionDecoder")
            decoder = try DiscordOpusDecoder(sampleRate: 48_000, channels: 2)
            decoders[packet.ssrc] = decoder
        }

        guard let previousSeqNum = sequences[packet.ssrc], let previousTimestamp = timestamps[packet.ssrc] else {
            sequences[packet.ssrc] = packet.seqNum
            timestamps[packet.ssrc] = packet.timestamp

            throw DiscordVoiceError.initialPacket
        }

        guard packet.seqNum == previousSeqNum &+ 1 else {
            if packet.seqNum < previousSeqNum {
                // Don't handle old packets
                throw DiscordVoiceError.decodeFail
            }

            sequences[packet.ssrc] = packet.seqNum
            timestamps[packet.ssrc] = packet.timestamp

            DefaultDiscordLogger.Logger.debug("Out of order packet", type: "DiscordVoiceSessionDecoder")
            DefaultDiscordLogger.Logger.debug("Looks to have a sequence difference of \(packet.seqNum - previousSeqNum)", type: "DiscordVoiceSessionDecoder")

            for _ in 0..<packet.seqNum-previousSeqNum {
                // TODO Don't hardcode the frameSize
                _ = try decoder.decode(nil, packetSize: 0, frameSize: 960)
            }

            throw DiscordVoiceError.decodeFail
        }

        let decoded = try packet.voiceData.withUnsafeBytes {bytes -> [opus_int16] in
            let pointer = bytes.baseAddress!.assumingMemoryBound(to: UInt8.self)

            return try decoder.decode(pointer,
                                      packetSize: packet.voiceData.count,
                                      frameSize: packet.timestamp - previousTimestamp)
        }

        sequences[packet.ssrc] = packet.seqNum
        timestamps[packet.ssrc] = packet.timestamp

        return DiscordRawVoiceData(opusPacket: packet, rawVoice: decoded)
    }
}

///
/// An Opus decoder.
///
/// Takes Opus packets and returns raw PCM 16-bit-lesample data.
///
open class DiscordOpusDecoder : DiscordOpusCodeable {
    // MARK: Properties

    /// The number of channels.
    public let channels: Int

    /// The sampling rate.
    public let sampleRate: Int

    private let decoderState: OpaquePointer

    // MARK: Initializers

    ///
    /// Creates a Decoder that takes Opus encoded data and outputs raw PCM 16-bit-lesample data.
    ///
    /// - parameter sampleRate: The sample rate for the decoder. Discord expects this to be 48k.
    /// - parameter channels: The number of channels in the stream to decode, should always be 2.
    /// - parameter gain: The gain for this decoder.
    ///
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

    ///
    /// Decodes Opus data into raw PCM 16-bit-lesample data.
    ///
    /// - parameter audio: A pointer to the audio data.
    /// - parameter packetSize: The number of bytes in this packet.
    /// - parameter frameSize: The size of the frame in samples per channel.
    /// - returns: An opus encoded packet.
    ///
    open func decode(_ audio: UnsafePointer<UInt8>?, packetSize: Int, frameSize: Int) throws -> [opus_int16] {
        let maxSize = maxFrameSize(assumingSize: frameSize)
        let output = UnsafeMutablePointer<opus_int16>.allocate(capacity: maxSize)
        let decodedSize = Int(opus_decode(decoderState, audio, Int32(packetSize), output, Int32(frameSize), 0))
        let totalSize = decodedSize * channels

        defer { free(output) }

        guard decodedSize > 0, totalSize <= maxSize else { throw DiscordVoiceError.decodeFail }

        return Array(UnsafeBufferPointer(start: output, count: totalSize))
    }
}

/// A struct that contains a Discord voice packet with raw data.
public struct DiscordRawVoiceData {
    /// The sequence number of this packet.
    public let seqNum: Int

    /// The source of this packet.
    public let ssrc: Int

    /// The timestamp of this packet.
    public let timestamp: Int

    /// The raw voice data.
    public let voiceData: [Int16]

    fileprivate init(opusPacket: DiscordOpusVoiceData, rawVoice: [Int16]) {
        seqNum = opusPacket.seqNum
        ssrc = opusPacket.ssrc
        timestamp = opusPacket.timestamp
        voiceData = rawVoice
    }
}

/// A struct that contains a Discord voice packet with Opus encoded data.
public struct DiscordOpusVoiceData {
    /// The sequence number of this packet.
    public let seqNum: Int

    /// The source of this packet.
    public let ssrc: Int

    /// The timestamp of this packet.
    public let timestamp: Int

    /// The raw voice data.
    public let voiceData: [UInt8]

    init(voicePacket: [UInt8]) {
        let rtpHeader = Array(voicePacket.prefix(12)).map(Int.init(_:))

        voiceData = Array(voicePacket.dropFirst(12))
        seqNum = rtpHeader[2] << 8 | rtpHeader[3]
        timestamp = rtpHeader[4] << 24 | rtpHeader[5] << 16 | rtpHeader[6] << 8 | rtpHeader[7]
        ssrc = rtpHeader[8] << 24 | rtpHeader[9] << 16 | rtpHeader[10] << 8 | rtpHeader[11]
    }
}
