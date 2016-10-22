import Foundation

public protocol DiscordVoiceEngineSpec : DiscordEngineSpec {
	var encoder: DiscordVoiceEncoder? { get }
	var secret: [UInt8]! { get }

	func requestNewEncoder()
	func send(_ data: Data, doneHandler: (() -> Void)?)
	func sendVoiceData(_ data: Data)
}

public extension DiscordVoiceEngineSpec {
    public func send(_ data: Data, doneHandler: (() -> Void)? = nil) {
        encoder?.write(data, doneHandler: doneHandler)
    }
}
