import Foundation

public protocol DiscordClientSpec : class, DiscordEngineClient {
	var connected: Bool { get }
	var guilds: [String: DiscordGuild] { get }
	var isBot: Bool { get }
	var relationships: [[String: Any]] { get } // TODO make this a [DiscordRelationship]
	var token: String { get }
	var user: DiscordUser? { get }
	var voiceState: DiscordVoiceState? { get }

	init(token: String)

	func connect()
	func disconnect()
	func on(_ event: String, callback: @escaping ([Any]) -> Void)
	func handleEvent(_ event: String, with data: [Any])
	func getMessages(for channel: String, options: [DiscordEndpointOptions.GetMessage],
		callback: @escaping ([DiscordMessage]) -> Void)
	func joinVoiceChannel(_ channelId: String, callback: @escaping (String) -> Void)
	func leaveVoiceChannel(_ channelId: String)
	func sendMessage(_ message: String, to channelId: String, tts: Bool)
}
