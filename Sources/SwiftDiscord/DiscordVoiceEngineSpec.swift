import Foundation

public protocol DiscordVoiceEngineSpec : DiscordEngineSpec {
	func sendVoiceData(_ data: Data)
}
