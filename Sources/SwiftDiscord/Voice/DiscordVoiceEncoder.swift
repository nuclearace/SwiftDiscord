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
import Dispatch
import Foundation

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

#if !os(iOS)
///
/// A wrapper class for a process that spits out audio data that can be fed into an FFmpeg process that is then sent
/// to the engine.
///
///
public class DiscordEncoderMiddleware {
    // MARK: Properties

    /// The FFmpeg process.
    public let ffmpeg: Process

    /// The middleware process.
    public let middleware: Process

    /// The pipe used to connect FFmpeg to the middleware.
    public let pipe: Pipe

    // MARK: Initializers

    ///
    /// An intializer that sets up a middleware ffmpeg process that encodes some audio data.
    ///
    public init(encoder: DiscordVoiceEncoder, middleware: Process, terminationHandler: (() -> ())?) {
        self.middleware = middleware
        ffmpeg = Process()
        pipe = Pipe()

        middleware.standardOutput = pipe

        ffmpeg.launchPath = "/usr/local/bin/ffmpeg"
        ffmpeg.standardInput = pipe
        ffmpeg.standardOutput = encoder.writeToHandler
        ffmpeg.arguments = ["-hide_banner", "-loglevel", "quiet", "-i", "pipe:0", "-f", "s16le", "-map", "0:a",
                            "-ar", "48000", "-ac", "2", "-b:a", "128000", "-acodec", "pcm_s16le", "pipe:1"]

        middleware.terminationHandler = {_ in
            terminationHandler?()
        }

        ffmpeg.terminationHandler = {[weak encoder] _ in
            encoder?.finishUpAndClose()
        }
    }

    ///
    /// Starts the middleware.
    ///
    public func start() {
        ffmpeg.launch()
        middleware.launch()
    }
}
#endif

///
/// DiscordVoiceEncoder is responsible for turning audio data into Opus packets.
///
open class DiscordVoiceEncoder : DiscordVoiceEngineDataSource {
    // MARK: Properties

    private static let logType =  "DiscordVoiceEncoder"

    /// The Opus encoder.
    public let opusEncoder: DiscordOpusEncoder

    /// The size of a frame in samples per channel. Needed to calculate the maximum size of a frame.
    public var frameSize = 960

    #if !os(iOS)
    /// A middleware process that spits out raw PCM for the encoder.
    public var middleware: DiscordEncoderMiddleware?
    #endif

    /// What the encoder reads from, and what a consumer writes to to have things encoded into Opus
    public private(set) var pipe: Pipe

    /// A file handle that can be used to write to the encoder.
    /// - returns: A file handle that can be written to.
    public var writeToHandler: FileHandle {
        // iOS doesn't have FFmpeg middleware. So it's safe to return what normally is the write to FFmpeg.
        return pipe.fileHandleForWriting
    }

    private let readQueue = DispatchQueue(label: "discordVoiceEncoder.readQueue")
    private var closed = false
    private var done = false
    private var source: DispatchIO!
    private var readBuffer = [[UInt8]]()

    // MARK: Initializers

    ///
    /// Sets up a raw encoder. This contains no FFmpeg middleware, so you must write raw PCM data to the encoder.
    ///
    /// - parameter opusEncoder: The Opus encoder to use.
    ///
    public init(opusEncoder: DiscordOpusEncoder) {
        self.pipe = Pipe()
        self.opusEncoder = opusEncoder
        createDispatchIO()
    }

    deinit {
        DefaultDiscordLogger.Logger.debug("deinit", type: "DiscordVoiceEncoder")

        guard !closed else { return }

        closeEncoder()
    }

    // MARK: Methods

    /// Abrubtly halts encoding and kills the encoder
    open func closeEncoder() {
        defer { closed = true }

        // Cancel any reading we were doing
        pipe.fileHandleForReading.closeFile()
        pipe.fileHandleForWriting.closeFile()
    }

    private func createDispatchIO() {
        self.source = DispatchIO(type: .stream, fileDescriptor: pipe.fileHandleForReading.fileDescriptor,
                                 queue: readQueue, cleanupHandler: {[weak self] code in
            self?.setupPipe()
        })
    }

    ///
    /// Called when the engine needs voice data. If there is no more data left,
    /// a `DiscordVoiceEngineDataSourceStatus.done` error should be thrown.
    ///
    /// - parameter engine: The voice engine that needs data.
    /// - returns: An array of Opus encoded bytes.
    open func engineNeedsData(_ engine: DiscordVoiceEngine) throws -> [UInt8] {
        var data: [UInt8]!
        var done: Bool!

        readQueue.sync {
            done = self.done
            guard self.readBuffer.count != 0 else { return }

            data = self.readBuffer.removeFirst()
        }

        guard data != nil else {
            if done {
                throw DiscordVoiceEngineDataSourceStatus.done
            } else {
                throw DiscordVoiceEngineDataSourceStatus.noData
            }
        }

        return data
    }

    /// Call only when you know you've finished writing data, but ffmpeg is still encoding, or has data we haven't read
    /// This should cause ffmpeg to get an EOF on input, which will cause it to close once its output buffer is empty
    open func finishUpAndClose() {
        guard !closed else { return }

        DefaultDiscordLogger.Logger.debug("Closing pipe for writing", type: "DiscordVoiceEncoder")

        writeToHandler.closeFile()
    }

    ///
    /// Starts listening to the writePipe.
    ///
    open func startReading() {
        guard !closed else { return }

        _read()
    }

    private func _read() {
        let maxFrameSize = opusEncoder.maxFrameSize(assumingSize: frameSize)

        source.read(offset: 0, length: maxFrameSize, queue: readQueue, ioHandler: {[weak self] done, data, code in
            guard let this = self else { return }

            guard let data = data, data.count > 0 else {
                DefaultDiscordLogger.Logger.debug("No data, reader probably closed", type: DiscordVoiceEncoder.logType)
                // EOF reached
                if done && code == 0 {
                    DefaultDiscordLogger.Logger.debug("Reader done", type: DiscordVoiceEncoder.logType)
                    this.done = true

                    return
                }

                this._read()
                return
            }

            DefaultDiscordLogger.Logger.debug("Read \(data.count) bytes", type: DiscordVoiceEncoder.logType)

            do {
                try data.withUnsafeBytes {(bytes: UnsafePointer<opus_int16>) in
                    // TODO don't bloat the buffer to huge sizes
                    this.readBuffer.append(try this.opusEncoder.encode(bytes, frameSize: this.frameSize))
                }

                this._read()
            } catch {
                DefaultDiscordLogger.Logger.error("Error encoding bytes", type: DiscordVoiceEncoder.logType)
            }
        })
    }

    // Sets up a new pipe for reading/writing.
    // TODO Does this make sense anymore?
    func setupPipe() {
        readQueue.sync {
            self.done = false
            self.pipe = Pipe()
            self.createDispatchIO()
        }
    }

    ///
    /// Writes to the encoder.
    ///
    /// - parameter data: Raw audio data that should be turned into OPUS encoded data.
    /// - parameter doneHandler: An optional handler that will be called when we are done writing.
    ///
    open func write(_ data: Data, doneHandler: (() -> ())? = nil) {
        guard !closed else { return }

        // FileHandle's write doesn't play nicely with the way we use pipes
        // It will throw an exception that we cannot catch if the write handle is closed
        // So do basically exactly what it does, but don't explode the app when the handle is closed
        let fd = writeToHandler.fileDescriptor
        data.enumerateBytes {bytes, range, stop in
            let buf = UnsafeRawPointer(bytes.baseAddress!)
            var bytesRemaining = data.count

            while bytesRemaining > 0 {
                var bytesWritten: Int

                repeat {
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
    public init(bitrate: Int, sampleRate: Int, channels: Int, vbr: Bool = false) throws {
        self.bitrate = bitrate
        self.sampleRate = sampleRate
        self.channels = channels

        var err = 0 as Int32

        encoderState = opus_encoder_create(Int32(sampleRate), Int32(channels), OPUS_APPLICATION_VOIP, &err)
        err = configure_encoder(encoderState, Int32(bitrate), vbr ? 1 : 0)

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
        opus_encoder_destroy(encoderState)
    }

    ///
    /// Encodes a single frame of raw PCM 16-bit-lesample LE data into Opus format.
    ///
    /// - parameter audio: A pointer to the audio data. Use `maxFrameSize(assumingSize:)` to find the length.
    /// - parameter frameSize: The size of the frame in samples per channel.
    /// - returns: An opus encoded packet.
    ///
    open func encode(_ audio: UnsafePointer<opus_int16>, frameSize: Int) throws -> [UInt8] {
        let output = UnsafeMutablePointer<UInt8>.allocate(capacity: maxPacketSize)
        let lenPacket = opus_encode(encoderState, audio, Int32(frameSize), output, opus_int32(maxPacketSize))

        defer { free(output) }

        guard lenPacket > 0 else { throw DiscordVoiceError.encodeFail }

        return Array(UnsafeBufferPointer(start: output, count: Int(lenPacket)))
    }
}
