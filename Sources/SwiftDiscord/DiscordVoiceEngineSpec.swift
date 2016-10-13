import Foundation

public protocol DiscordVoiceEngineSpec : DiscordEngineSpec {
	var encoder: DiscordVoiceEncoder? { get }
	var secret: [UInt8]! { get }

	func requestNewEncoder()
	func sendVoiceData(_ data: Data)
}
