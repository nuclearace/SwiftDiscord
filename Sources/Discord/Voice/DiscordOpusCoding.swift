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
import Foundation

/// Declares that a type has enough information to encode/decode Opus data.
public protocol DiscordOpusCodeable {
    // MARK: Properties

    /// The number of channels.
    var channels: Int { get }

    /// The sampling rate.
    var sampleRate: Int { get }

    // MARK: Methods

    ///
    /// Returns the maximum number of bytes that a frame can contain given a
    /// frame size in number of samples per channel.
    ///
    /// - parameter assumingSize: The size of the frame, in number of samples per channel.
    /// - returns: The number of bytes in this frame.
    ///
    func maxFrameSize(assumingSize size: Int) -> Int
}

public extension DiscordOpusCodeable {
    ///
    /// Returns the maximum number of bytes that a frame can contain given a
    /// frame size in number of samples per channel.
    ///
    /// - parameter assumingSize: The size of the frame, in number of samples per channel.
    /// - returns: The number of bytes in this frame.
    ///
    func maxFrameSize(assumingSize size: Int) -> Int {
        return size * channels * MemoryLayout<opus_int16>.size
    }
}

///
/// An Opus encoder.
///
/// Takes raw PCM 16-bit-lesample data and returns Opus encoded voice packets.
///
open class DiscordOpusEncoder : DiscordOpusCodeable {
    // MARK: Properties

    /// The bitrate for this encoder.
    public let bitrate: Int

    /// The number of channels.
    public let channels: Int

    /// The maximum size of a opus packet.
    public var maxPacketSize: Int { return 4000 }

    /// The sampling rate.
    public let sampleRate: Int

    private let encoderState: OpaquePointer

    // MARK: Initializers

    ///
    /// Creates an Encoder that can take raw PCM data and create Opus packets.
    ///
    /// - parameter bitrate: The target bitrate for this encoder.
    /// - parameter sampleRate: The sample rate for the encoder. Discord expects this to be 48k.
    /// - parameter channels: The number of channels in the stream to encode, should always be 2.
    ///
    public init(bitrate: Int, sampleRate: Int = 48_000, channels: Int = 2, vbr: Bool = false) throws {
        self.bitrate = bitrate
        self.sampleRate = sampleRate
        self.channels = channels

        var err = 0 as Int32

        encoderState = opus_encoder_create(Int32(sampleRate), Int32(channels), OPUS_APPLICATION_VOIP, &err)
        let err2 = opus_encoder_set_bitrate(encoderState, Int32(bitrate))
        let err3 = opus_encoder_set_vbr(encoderState, vbr ? 1 : 0)

        guard err == 0, err2 == 0, err3 == 0 else {
            destroyState()

            throw DiscordVoiceError.creationFail
        }
    }

    deinit {
        destroyState()
    }

    // MARK: Methods

    private func destroyState() {
        opus_encoder_destroy(encoderState)
    }

    ///
    /// Encodes a single frame of raw PCM 16-bit-le/sample LE data into Opus format.
    ///
    /// - parameter audio: A pointer to the audio data. Use `maxFrameSize(assumingSize:)` to find the length.
    /// - parameter frameSize: The size of the frame in samples per channel.
    /// - returns: An opus encoded packet.
    ///
    open func encode(_ audio: UnsafePointer<opus_int16>, frameSize: Int) throws -> [UInt8] {
        let output = UnsafeMutablePointer<UInt8>.allocate(capacity: maxPacketSize)
        let lenPacket = opus_encode(encoderState, audio, Int32(frameSize), output, opus_int32(maxPacketSize))

        defer { output.deallocate() }

        guard lenPacket > 0 else { throw DiscordVoiceError.encodeFail }

        return Array(UnsafeBufferPointer(start: output, count: Int(lenPacket)))
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
        let err2 = opus_decoder_set_gain(decoderState, Int32(gain))

        guard err == 0, err2 == 0 else {
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

        defer { output.deallocate() }

        guard decodedSize > 0, totalSize <= maxSize else { throw DiscordVoiceError.decodeFail }

        return Array(UnsafeBufferPointer(start: output, count: totalSize))
    }
}
