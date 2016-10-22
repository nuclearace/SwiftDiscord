import Foundation

public class DiscordVoiceEncoder {
	public let ffmpeg: Process
	public let reader: FileHandle
	public let readPipe: Pipe
	public let writePipe: Pipe

	private let readIO: DispatchIO
	private let readQueue = DispatchQueue(label: "discordVoiceEngine.readQueue")
	private let writeQueue = DispatchQueue(label: "discordEngine.writeQueue")

	private var encoderClosed = false

	public init(ffmpeg: Process, readPipe: Pipe, writePipe: Pipe) {
		self.ffmpeg = ffmpeg
		self.reader = writePipe.fileHandleForReading
		self.readPipe = readPipe
		self.writePipe = writePipe
		self.readIO = DispatchIO(type: .stream, fileDescriptor: reader.fileDescriptor, queue: readQueue,
			cleanupHandler: {_ in })

		readIO.setLimit(lowWater: 1)

		self.ffmpeg.launch()
	}

	deinit {
		// print("encoder going bye bye")

		guard !encoderClosed else { return }

		closeEncoder()
	}

	// Abrubtly halts encoding and kills ffmpeg
	public func closeEncoder() {
		kill(ffmpeg.processIdentifier, SIGKILL)

		closeReader()
		ffmpeg.waitUntilExit()

		encoderClosed = true
	}

	public func closeReader() {
		readIO.close(flags: .stop)
	}

	/// Call only when you know you've finished writing data, but ffmpeg is still encoding, or has data we haven't read
	public func finishEncodingAndClose() {
		close(readPipe.fileHandleForWriting.fileDescriptor)
	}

	public func read(callback: @escaping (Bool, DispatchData?, Int32) -> Void) {
		readIO.read(offset: 0, length: 320, queue: readQueue, ioHandler: callback)
	}

	public func write(_ data: Data, doneHandler: (() -> Void)? = nil) {
		writeQueue.async {[weak self] in
			data.enumerateBytes {bytes, range, stop in
				let buf = UnsafeRawPointer(bytes.baseAddress!)
				var bytesRemaining = data.count

				while bytesRemaining > 0 {
					var bytesWritten: Int

					repeat {
						guard let fd = self?.readPipe.fileHandleForWriting.fileDescriptor else { return }

						bytesWritten = Darwin.write(fd, buf.advanced(by: data.count - bytesRemaining), bytesRemaining)
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
