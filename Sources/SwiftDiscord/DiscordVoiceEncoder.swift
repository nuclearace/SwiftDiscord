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

#if !os(iOS)

import Foundation
import Dispatch

public class DiscordVoiceEncoder {
	public let encoder: EncoderProcess
	public let readPipe: Pipe
	public let writePipe: Pipe

	private let readQueue = DispatchQueue(label: "discordVoiceEncoder.readQueue")
	private let writeQueue = DispatchQueue(label: "discordVoiceEncoder.writeQueue")

	private let id = arc4random()


	private var closed = false

	/// readPipe: What the encoder reads from, and what we write to to have things encoded into OPUS
	/// writePipe: What the encoder writes to, and what we read from to get OPUS encoded data
	public init(encoder: EncoderProcess, readPipe: Pipe, writePipe: Pipe) {
		self.encoder = encoder
		self.readPipe = readPipe
		self.writePipe = writePipe

		self.encoder.launch()
	}

	public convenience init() {
		let ffmpeg = EncoderProcess()
		let writePipe = Pipe()
		let readPipe = Pipe()

		ffmpeg.launchPath = "/usr/local/bin/ffmpeg"
		ffmpeg.standardInput = readPipe.fileHandleForReading
		ffmpeg.standardOutput = writePipe.fileHandleForWriting
		ffmpeg.arguments = ["-hide_banner", "-loglevel", "quiet", "-i", "pipe:0", "-f", "data", "-map", "0:a", "-ar",
			"48000", "-ac", "2", "-acodec", "libopus", "-sample_fmt", "s16", "-vbr", "off", "-b:a", "128000",
			"-compression_level", "10", "pipe:1"]

		self.init(encoder: ffmpeg, readPipe: readPipe, writePipe: writePipe)

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

	deinit {
		guard !closed else { return }

		closeEncoder()
	}

	/// Abrubtly halts encoding and kills the encoder
	public func closeEncoder() {
		defer { closed = true }
		guard encoder.isRunning else { return }

		kill(encoder.processIdentifier, SIGKILL)

		// Wait for the encoder to expire so that the pipes get closed
		encoder.waitUntilExit()
		// Cancel any reading we were doing
		close(writePipe.fileHandleForReading.fileDescriptor)
		// Wait until a dummy block gets executed. That way any pending reads see that they are done reading
		readQueue.sync {}
	}

	/// Call only when you know you've finished writing data, but ffmpeg is still encoding, or has data we haven't read
	/// This should cause ffmpeg to get an EOF on input, which will cause it to close once its output buffer is empty
	public func finishEncodingAndClose() {
		guard !closed else { return }

		close(readPipe.fileHandleForWriting.fileDescriptor)
	}

	public func read(callback: @escaping (Bool, [UInt8]) -> Void) {
		guard !closed else { return callback(true, []) }

		readQueue.async {[weak self] in
			guard let fd = self?.writePipe.fileHandleForReading.fileDescriptor else { return }
			defer { free(buf) }

			let buf = UnsafeMutableRawPointer.allocate(bytes: defaultAudioSize, alignedTo: 16)
			let bytesRead = Foundation.read(fd, buf, defaultAudioSize)

			// Error reading or done
			guard bytesRead > 0 else { return callback(true, []) }

            let pointer = buf.assumingMemoryBound(to: UInt8.self)
            let byteArray = Array(UnsafeBufferPointer(start: pointer, count: defaultAudioSize))

            callback(false, byteArray)
		}
	}

	public func write(_ data: Data, doneHandler: (() -> Void)? = nil) {
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
						guard let fd = self?.readPipe.fileHandleForWriting.fileDescriptor else { return }

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

#endif
