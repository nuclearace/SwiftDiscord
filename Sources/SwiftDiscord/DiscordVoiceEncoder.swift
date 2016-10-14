import Foundation

public class DiscordVoiceEncoder {
	public let ffmpeg: Process
	public let reader: FileHandle
	public let readPipe: Pipe
	public let writePipe: Pipe

	var readIO: DispatchIO

	private let readQueue = DispatchQueue(label: "discordVoiceEngine.readQueue")
	private let writeQueue = DispatchQueue(label: "discordEngine.writeQueue")

	public init(ffmpeg: Process, reader: FileHandle, readPipe: Pipe, writePipe: Pipe) {
		self.ffmpeg = ffmpeg
		self.reader = reader
		self.readPipe = readPipe
		self.writePipe = writePipe
		self.readIO = DispatchIO(type: .stream, fileDescriptor: reader.fileDescriptor, queue: readQueue,
			cleanupHandler: {n in
				print("closed")
		})

		readIO.setLimit(lowWater: 1)

		self.ffmpeg.launch()
	}

	public func closeEncoder() {
		ffmpeg.terminate()
		readIO.close(flags: .stop)

		// Block so readIO can get the stop signal
		readQueue.sync {}
	}

	public func read(callback: @escaping (Bool, DispatchData?, Int32) -> Void) {
		readIO.read(offset: 0, length: 320, queue: readQueue, ioHandler: callback)
	}

	public func write(_ data: Data) {
		writeQueue.async {[weak self] in
			data.enumerateBytes { (bytes, range, stop) in
				let buf = UnsafeRawPointer(bytes.baseAddress!)
				var bytesRemaining = data.count

				while bytesRemaining > 0 {
					var bytesWritten: Int

					repeat {
						guard let this = self else { return }

						let fd = this.readPipe.fileHandleForWriting.fileDescriptor

						bytesWritten = Darwin.write(fd, buf.advanced(by: data.count - bytesRemaining), bytesRemaining)
					} while bytesWritten < 0 && errno == EINTR

					if bytesWritten <= 0 {
						// Something went wrong
						break
					} else {
						bytesRemaining -= bytesWritten
					}
				}
			}
		}
	}

	deinit {
		print("encoder going bye bye")
		closeEncoder()
	}
}
