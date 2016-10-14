import Foundation

public class DiscordVoiceEncoder {
	public let ffmpeg: Process
	public let reader: FileHandle
	public let readPipe: Pipe
	public let writePipe: Pipe

	var readIO: DispatchIO

	private let writeQueue = DispatchQueue(label: "discordEngine.writeQueue")

	public init(ffmpeg: Process, reader: FileHandle, readPipe: Pipe, writePipe: Pipe, readIO: DispatchIO) {
		self.ffmpeg = ffmpeg
		self.reader = reader
		self.readPipe = readPipe
		self.writePipe = writePipe
		self.readIO = readIO

		self.ffmpeg.launch()
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
		ffmpeg.terminate()
		readIO.close(flags: .stop)
	}
}
