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
import DiscordOpus
import Dispatch
import Foundation

/// Represents an error that can occur during voice operations.
public enum DiscordVoiceError : Error {
    case creationFail
    case encodeFail
}

/**
    DiscordVoiceEncoder is responsible for turning audio data into Opus packets. Depending on the initializer,
    it can use FFmpeg as a middleware to turn audio of different formats into raw PCM that the OpusEncoder in turn
    turns into Opus packets.
*/
open class DiscordVoiceEncoder {
    // MARK: Properties

    #if !os(iOS)
    /// A process that can turn whatever into PCM data.
    public let encoder: EncoderProcess
    #endif

    /// The Opus encoder.
    public let opusEncoder: DiscordOpusEncoder

    /// What the encoder reads from, and what a consumer writes to to have things encoded into Opus
    public let readPipe: Pipe

    /// What the encoder writes to, and what a consumer reads from to get Opus encoded data
    public let writePipe: Pipe

    /// The size of a frame in samples per channel. Needed to calculate the maximum size of a frame.
    public var frameSize = 960

    /// A file handle that can be used to write to the encoder.
    /// - returns: A file handle that can be written to.
    public var writeToHandler: FileHandle {
        // iOS doesn't have FFmpeg middleware. So it's safe to return what normally is the write to FFmpeg.
        return readPipe.fileHandleForWriting
    }

    private let readQueue = DispatchQueue(label: "discordVoiceEncoder.readQueue")
    private let writeQueue = DispatchQueue(label: "discordVoiceEncoder.writeQueue")

    private var closed = false

    // MARK: Initializers

    /**
        Sets up a raw encoder. This contains no FFmpeg middleware, so you must write raw PCM data to the encoder.

        - parameter opusEncoder: The Opus encoder to use.
    */
    public init(opusEncoder: DiscordOpusEncoder) {
        let pipe = Pipe() // No middleware here, just one pipe is needed

        self.readPipe = pipe
        self.writePipe = pipe
        self.opusEncoder = opusEncoder
        #if !os(iOS)
        self.encoder = EncoderProcess()
        #endif
    }

    #if !os(iOS)
    /**
        Sets up an encoder with FFmpeg middleware that can make going from audio files to Opus easier on the user.

        - parameter encoder: The FFmpeg process
        - parameter readPipe: What the encoder reads from, and what a consumer writes to to have things encoded
                              into Opus
        - parameter writePipe: What the encoder writes to, and what a consumer reads from to get Opus encoded data
    */
    public init(encoder: EncoderProcess, opusEncoder: DiscordOpusEncoder, readPipe: Pipe, writePipe: Pipe) {
        self.encoder = encoder
        self.readPipe = readPipe
        self.writePipe = writePipe
        self.opusEncoder = opusEncoder

        self.encoder.launch()
    }

    /**
        A convenience intializer that sets up a ffmpeg process to do encoding.
    */
    public convenience init() throws {
        let ffmpeg = EncoderProcess()
        let writePipe = Pipe()
        let readPipe = Pipe()
        let opusEncoder = try DiscordOpusEncoder(bitrate: 128_000, sampleRate: 48_000, channels: 2)

        ffmpeg.launchPath = "/usr/local/bin/ffmpeg"
        ffmpeg.standardInput = readPipe.fileHandleForReading
        ffmpeg.standardOutput = writePipe.fileHandleForWriting
        ffmpeg.arguments = ["-hide_banner", "-loglevel", "quiet", "-i", "pipe:0", "-f", "s16le", "-map", "0:a",
            "-ar", "48000", "-ac", "2", "-b:a", "128000", "-acodec", "pcm_s16le", "pipe:1"]

        self.init(encoder: ffmpeg, opusEncoder: opusEncoder, readPipe: readPipe, writePipe: writePipe)

        encoder.terminationHandler = {[weak self] _ in
            guard let this = self else { return }

            // Make sure the pipes are closed
            // Don't close the read end of the encoder's writePipe, since we might still be reading from it
            // It'll get closed when we deinit
            close(this.readPipe.fileHandleForReading.fileDescriptor)
            close(this.readPipe.fileHandleForWriting.fileDescriptor)
            close(this.writePipe.fileHandleForWriting.fileDescriptor)
        }
    }
    #endif

    deinit {
        DefaultDiscordLogger.Logger.debug("deinit", type: "DiscordVoiceEncoder")

        guard !closed else { return }

        closeEncoder()
    }

    // MARK: Methods


    /// Abrubtly halts encoding and kills the encoder
    open func closeEncoder() {
        defer { closed = true }
        #if !os(iOS)
        guard encoder.isRunning else { return }

        kill(encoder.processIdentifier, SIGKILL)

        // Wait for the encoder to expire so that the pipes get closed
        encoder.waitUntilExit()
        #endif

        // Cancel any reading we were doing
        close(writePipe.fileHandleForReading.fileDescriptor)

        let waiter = DispatchSemaphore(value: 0)

        // Wait until a dummy block gets executed. That way any pending reads see that they are done reading
        readQueue.async {
            waiter.signal()
        }

        waiter.wait()
    }

    /// Call only when you know you've finished writing data, but ffmpeg is still encoding, or has data we haven't read
    /// This should cause ffmpeg to get an EOF on input, which will cause it to close once its output buffer is empty
    open func finishEncodingAndClose() {
        guard !closed else { return }

        close(readPipe.fileHandleForWriting.fileDescriptor)
    }

    /**
        An async read from the encoder. When there is available data, then callback is called.

        - parameter callback: A callback that will be called when there is available data, or when the encoder is done.
                        First parameter is a Bool indicating whether the encoder is done.
                        Second is the OPUS encoded data in an array.
    */
    open func read(callback: @escaping (Bool, [UInt8]) -> Void) {
        guard !closed else { return callback(true, []) }

        readQueue.async {[weak opusEncoder,
                          maxFrameSize = opusEncoder.maxFrameSize(assumingSize: frameSize),
                          frameSize = self.frameSize,
                          fd = writePipe.fileHandleForReading.fileDescriptor] in
            defer { free(buf) }

            // Read one frame
            let buf = UnsafeMutableRawPointer.allocate(bytes: maxFrameSize, alignedTo: MemoryLayout<UInt8>.alignment)
            let bytesRead = Foundation.read(fd, buf, maxFrameSize)

            DefaultDiscordLogger.Logger.debug("Read %@ bytes", type: "DiscordVoiceEncoder", args: bytesRead)

            guard bytesRead > 0, let encoder = opusEncoder else {
                callback(true, [])

                return
            }

            let pointer = buf.assumingMemoryBound(to: opus_int16.self)

            do {
                callback(false, try encoder.encode(pointer, frameSize: frameSize))
            } catch {
                callback(true, [])
            }
        }
    }

    /**
        An async write to the encoder.

        - parameter data: Raw audio data that should be turned into OPUS encoded data.
        - parameter doneHandler: An optional handler that will be called when we are done writing.
    */
    open func write(_ data: Data, doneHandler: (() -> Void)? = nil) {
        guard !closed else { return }

        // FileHandle's write doesn't play nicely with the way we use pipes
        // It will throw an exception that we cannot catch if the write handle is closed
        // So do basically exactly what it does, but don't explode the app when the handle is closed
        writeQueue.async {[weak self] in
            data.enumerateBytes {bytes, range, stop in
                let buf = UnsafeRawPointer(bytes.baseAddress!)
                var bytesRemaining = data.count

                while bytesRemaining > 0 {
                    var bytesWritten: Int

                    repeat {
                        guard let fd = self?.writeToHandler.fileDescriptor else { return }

                        bytesWritten = Foundation.write(fd, buf.advanced(by: data.count - bytesRemaining), bytesRemaining)
                    } while bytesWritten < 0 && errno == EINTR

                    if bytesWritten <= 0 {
                        // Something went wrong
                        break
                    } else {
                        bytesRemaining -= bytesWritten
                    }
                }

                doneHandler?()
            }
        }
    }
}

/**
    An Opus encoder.

    Takes raw PCM 16-bit-le/sample data and returns Opus encoded voice packets.
*/
open class DiscordOpusEncoder {
    /// The bitrate for this encoder.
    public let bitrate: Int

    /// The number of channels.
    public let channels: Int

    /// The maximum size of a opus packet.
    public let maxPacketSize = 4000

    /// The sampling rate.
    public let sampleRate: Int

    private let encoderState: OpaquePointer

    public init(bitrate: Int, sampleRate: Int, channels: Int) throws {
        self.bitrate = bitrate
        self.sampleRate = sampleRate
        self.channels = channels

        var err = 0 as Int32

        encoderState = opus_encoder_create(Int32(sampleRate), Int32(channels), OPUS_APPLICATION_VOIP, &err)
        err = configure_encoder(encoderState, Int32(bitrate), 1)

        guard err == 0 else {
            destroyState()

            throw DiscordVoiceError.creationFail
        }
    }

    deinit {
        destroyState()
    }

    private func destroyState() {
        opus_encoder_destroy(encoderState)
    }

    /**
        Encodes a single frame of raw PCM 16-bit-le/sample LE data into Opus format.

        - parameter audio: A pointer to the audio data. Use `maxFrameSize(assumingSize:)` to find the length.
        - parameter frameSize: The size of the frame. Most likely 960.
        - returns: An opus encoded packet.
    */
    open func encode(_ audio: UnsafePointer<opus_int16>, frameSize: Int) throws -> [UInt8] {
        defer { free(output) }

        let output = UnsafeMutablePointer<UInt8>.allocate(capacity: maxPacketSize)
        let lenPacket = opus_encode(encoderState, audio, Int32(frameSize), output, opus_int32(maxPacketSize))

        guard lenPacket > 0 else { throw DiscordVoiceError.encodeFail }

        return Array(UnsafeBufferPointer(start: output, count: Int(lenPacket)))
    }

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
