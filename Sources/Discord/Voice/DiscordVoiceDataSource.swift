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
import Dispatch
import Foundation
import Logging

fileprivate let logger = Logger(label: "DiscordVoiceDataSource")

/// Specifies that a type will be a data source for a VoiceEngine.
public protocol DiscordVoiceDataSource : AnyObject {
    // MARK: Properties

    /// The size of a frame in samples per channel. Needed to calculate the maximum size of a frame.
    var frameSize: Int { get }

    // MARK: Methods

    ///
    /// Called when the engine needs voice data. If there is no more data left,
    /// a `DiscordVoiceDataSourceStatus.done` error should be thrown.
    ///
    /// - parameter engine: The voice engine that needs data.
    /// - returns: An array of Opus encoded bytes.
    ///
    func engineNeedsData(_ engine: DiscordVoiceEngine) throws -> [UInt8]

    ///
    /// Call when you want data collection to stop.
    ///
    func finishUpAndClose()

    /// Signals that the source should start producing data for consumption.
    func startReading()
}

/// Used to report the status of a data request if data could not be returned.
public enum DiscordVoiceDataSourceStatus : Error {
    /// Thrown when there is no more data left to be consumed.
    case done

    /// Special case used by the engine to tell itself that it should call for a new voice data source.
    case silenceDone(DiscordVoiceDataSource?)

    /// Thrown when an error occurs during a request.
    case error

    /// Thrown when there is no data to be read.
    case noData
}

///
/// DiscordBufferedVoiceDataSource is generic data source around a pipe. The only condition is that it expects raw
/// PCM 16-bit-le out of the pipe.
///
/// It buffers ~5 minutes worth of voice data
///
/// Usage:
///
/// ```swift
/// func client(_ client: DiscordClient, needsDataSourceForEngine engine: DiscordVoiceEngine) throws -> DiscordVoiceDataSource {
///     return DiscordBufferedVoiceDataSource(opusEncoder: try DiscordOpusEncoder(bitrate: 128_000))
///     // Somewhere down the line we setup some middleware which will use this source.
/// }
/// ```
///
open class DiscordBufferedVoiceDataSource : DiscordVoiceDataSource {
    // MARK: Properties

    /// The max number of voice packets to buffer.
    /// Roughly equal to `(nPackets * 20ms) / 1000 = seconds to buffer`.
    public let bufferSize: Int

    /// The number of packets that must be in the buffer before we start reading more into the buffer.
    public let drainThreshold: Int

    /// The queue for this encoder.
    public let encoderQueue = DispatchQueue(label: "discordVoiceEncoder.encoderQueue")

    /// The Opus encoder.
    public let opusEncoder: DiscordOpusEncoder

    /// The size of a frame in samples per channel. Needed to calculate the maximum size of a frame.
    public var frameSize = 960

    #if !os(iOS)
    /// A middleware process that spits out raw PCM for the encoder.
    public var middleware: DiscordEncoderMiddleware?
    #endif

    /// The DispatchIO source for this buffered source.
    public var source: DispatchIO!

    /// What the encoder reads from, and what a consumer writes to to have things encoded into Opus
    public private(set) var pipe: Pipe

    /// A file handle that can be used to write to the encoder.
    /// - returns: A file handle that can be written to.
    public var writeToHandler: FileHandle {
        // iOS doesn't have FFmpeg middleware. So it's safe to return what normally is the write to FFmpeg.
        return pipe.fileHandleForWriting
    }

    private var closed = false
    private var done = false
    private var drain = false
    private var readBuffer = [[UInt8]]()

    // MARK: Initializers

    ///
    /// Sets up a raw encoder. This contains no FFmpeg middleware, so you must write raw PCM data to the encoder.
    ///
    /// - parameter opusEncoder: The Opus encoder to use.
    /// - parameter bufferSize: The max number of voice packets to buffer.
    /// - parameter drainThreshold: The number of packets that must be in the buffer before we start reading more
    /// into the buffer.
    ///
    public init(opusEncoder: DiscordOpusEncoder, bufferSize: Int = 15_000, drainThreshold: Int = 13_500) {
        self.bufferSize = bufferSize
        self.drainThreshold = drainThreshold
        self.pipe = Pipe()
        self.opusEncoder = opusEncoder
        createDispatchIO()
    }

    deinit {
        logger.debug("deinit")

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

        source.close(flags: .stop)
    }

    ///
    /// Called when it is time to setup a `DispatchIO` for reading.
    ///
    /// Override to attach a custom file descriptor. By default it uses an internal pipe.
    ///
    open func createDispatchIO() {
        self.source = DispatchIO(type: .stream, fileDescriptor: pipe.fileHandleForReading.fileDescriptor,
                                 queue: encoderQueue, cleanupHandler: {code in
            logger.debug("Source spent: \(code)")
        })
    }

    ///
    /// Called when the engine needs voice data. If there is no more data left,
    /// a `DiscordVoiceEngineDataSourceStatus.done` error should be thrown.
    ///
    /// - parameter engine: The voice engine that needs data.
    /// - returns: An array of Opus encoded bytes.
    ///
    open func engineNeedsData(_ engine: DiscordVoiceEngine) throws -> [UInt8] {
        var data: [UInt8]!
        var done: Bool!

        encoderQueue.sync {
            done = self.done

            logger.trace("Buffer state: count: \(self.readBuffer.count) drain: \(self.drain)")

            if self.drain && self.readBuffer.count <= self.drainThreshold {
                // The swamp has been drained, start reading again
                logger.debug("Buffer drained, scheduling read")

                self.drain = false
                self.startReading()
            }

            guard self.readBuffer.count != 0 else { return }

            data = self.readBuffer.removeFirst()
        }

        guard data != nil else {
            if done {
                throw DiscordVoiceDataSourceStatus.done
            } else {
                throw DiscordVoiceDataSourceStatus.noData
            }
        }

        return data
    }

    /// Call only when you know you've finished writing data, but ffmpeg is still encoding, or has data we haven't read
    /// This should cause ffmpeg to get an EOF on input, which will cause it to close once its output buffer is empty
    open func finishUpAndClose() {
        guard !closed else { return }

        logger.debug("Closing pipe for writing")

        writeToHandler.closeFile()

        // DispatchIO on Linux doesn't seem to get EOF on pipe closes correctly
        #if os(Linux)
        source.close(flags: .stop)
        #endif
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

        source.read(offset: 0, length: maxFrameSize, queue: encoderQueue) {[weak self] done, data, code in
            guard let this = self else { return }

            guard let data = data, data.count > 0 else {
                logger.debug("No data, reader probably closed")

                this.done = true

                if done && code == 0 {
                    // EOF reached
                    logger.debug("Reader done")
                } else {
                    logger.debug("Something is weird \(done) \(code)")
                }

                return
            }

            logger.debug("Read \(data.count) bytes")

            do {
                try data.withUnsafeBytes {(bytes: UnsafePointer<opus_int16>) in
                    this.readBuffer.append(try this.opusEncoder.encode(bytes, frameSize: this.frameSize))
                }

                guard this.readBuffer.count < this.bufferSize else {
                    // Buffer is full; wait till it's drained
                    // Whatever is in charge of taking from the buffer should queue up more reading
                    logger.debug("Buffer full, not reading again")
                    this.drain = true

                    return
                }

                this._read()
            } catch {
                logger.error("Error encoding bytes")
            }
        }
    }
}

///
/// A subclass of `DiscordBufferedVoiceDataSource` that buffers a raw audio file.
///
/// Usage:
///
/// ```swift
/// func client(_ client: DiscordClient, needsDataSourceForEngine engine: DiscordVoiceEngine) throws -> DiscordVoiceDataSource {
///     return try DiscordVoiceFileDataSource(opusEncoder: try DiscordOpusEncoder(bitrate: 128_000),
///                                           file: URL(string: "file://output.raw")!)
/// }
/// ```
///
open class DiscordVoiceFileDataSource : DiscordBufferedVoiceDataSource {
    // MARK: Properties

    /// A FileHandle for reading the wrapped file.
    public let wrappedFile: FileHandle

    // MARK: Initializers

    ///
    /// Sets up a buffered source around a voice file.
    ///
    /// - parameter opusEncoder: The Opus encoder to use.
    /// - parameter file: A file to buffer around.
    /// - parameter bufferSize: The max number of voice packets to buffer.
    /// - parameter drainThreshold: The number of packets that must be in the buffer before we start reading more
    /// into the buffer.
    ///
    public init(opusEncoder: DiscordOpusEncoder,
                file: URL,
                bufferSize: Int = 15_000,
                drainThreshold: Int = 13_500) throws {
        self.wrappedFile = try FileHandle(forReadingFrom: file)

        super.init(opusEncoder: opusEncoder, bufferSize: bufferSize, drainThreshold: drainThreshold)
    }

    deinit {
        logger.debug("deinit")
    }

    // MARK: Methods

    ///
    /// Called when it is time to setup a `DispatchIO` for reading.
    ///
    /// Override to attach a custom file descriptor. By default it uses `wrappedFile`.
    ///
    open override func createDispatchIO() {
        self.source = DispatchIO(type: .stream, fileDescriptor: wrappedFile.fileDescriptor,
                                 queue: encoderQueue, cleanupHandler: {code in
            logger.debug("Source spent: \(code)")
        })
    }
}

///
/// A voice source that returns Opus silence.
/// Only sends 5 packets of silence and is then spent.
///
public final class DiscordSilenceVoiceDataSource : DiscordVoiceDataSource {
    /// The size of the frame.
    public let frameSize = 960

    /// The source from a previous engine that is being carried over.
    public let previousSource: DiscordVoiceDataSource?

    private var i = 0

    ///
    /// Creates a new silence data source. If `previousSource` is sent then when the silence data
    /// is used it the engine will attempt to use `previousSource` rather than asking for a new source.
    ///
    public init(previousSource: DiscordVoiceDataSource?) {
        self.previousSource = previousSource
    }

    ///
    /// Returns silence packets.
    ///
    /// - parameter engine: The engine requesting data.
    /// - returns: Opus encoded silence.
    ///
    public func engineNeedsData(_ engine: DiscordVoiceEngine) throws -> [UInt8] {
        guard i < 5 else { throw DiscordVoiceDataSourceStatus.silenceDone(previousSource) }

        i += 1

        return [0xF8, 0xFF, 0xFE]
    }

    ///
    /// Unimplemented
    ///
    public func finishUpAndClose() { }

    ///
    /// Unimplemented
    ///
    public func startReading() { }
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
    public init(source: DiscordBufferedVoiceDataSource, middleware: Process, terminationHandler: (() -> ())?) {
        self.middleware = middleware
        ffmpeg = Process()
        pipe = Pipe()

        middleware.standardOutput = pipe
        
        let ffmpegPath = "/usr/local/bin/ffmpeg"
        let ffmpegURL = URL(fileURLWithPath: ffmpegPath)
        
        pathSetter: do {
            #if os(macOS)
            guard #available(macOS 10.13, *) else {
                ffmpeg.launchPath = ffmpegPath
                break pathSetter
            }
            #endif
            ffmpeg.executableURL = ffmpegURL
        }

        ffmpeg.standardInput = pipe
        ffmpeg.standardOutput = source.writeToHandler
        ffmpeg.arguments = ["-hide_banner", "-loglevel", "quiet", "-i", "pipe:0", "-f", "s16le", "-map", "0:a",
                            "-ar", "48000", "-ac", "2", "-b:a", "128000", "-acodec", "pcm_s16le", "pipe:1"]

        middleware.terminationHandler = {_ in
            terminationHandler?()
        }

        ffmpeg.terminationHandler = {[weak source] _ in
            source?.finishUpAndClose()
        }
    }
    
    ///
    /// Starts the middleware.
    ///
    public func start() throws {
        #if os(macOS)
        guard #available(macOS 10.13, *) else {
            ffmpeg.launch()
            middleware.launch()
            return
        }
        #endif

        try ffmpeg.run()
        try middleware.run()
    }
}
#endif
