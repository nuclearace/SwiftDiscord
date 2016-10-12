import Foundation

public protocol DiscordVoiceEngineSpec : DiscordEngineSpec {
	func requestNewWriter()
	func sendVoiceData(_ data: Data)
}
