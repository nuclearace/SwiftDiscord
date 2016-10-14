import Foundation

public protocol DiscordVoiceEngineSpec : DiscordEngineSpec {
	var encoder: DiscordVoiceEncoder? { get }
	var secret: [UInt8]! { get }


	func requestNewEncoder()
	func send(_ data: Data)
	func sendVoiceData(_ data: Data)
}
