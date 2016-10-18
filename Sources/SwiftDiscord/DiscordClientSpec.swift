import Foundation

public protocol DiscordClientSpec : class, DiscordEngineClient {
	var connected: Bool { get }
	var guilds: [String: DiscordGuild] { get }
	var handleQueue: DispatchQueue { get set }
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
	func joinVoiceChannel(_ channelId: String, callback: @escaping (String) -> Void)
	func leaveVoiceChannel(_ channelId: String)
}
