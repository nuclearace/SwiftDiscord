import Foundation

public protocol DiscordClientSpec : class, DiscordEngineClient {
	var guilds: [String: DiscordGuild] { get }
	var relationships: [[String: Any]] { get } // TODO make this a [DiscordRelationship]
	var token: String { get }
	var user: DiscordUser? { get }

	init(token: String)

	func connect()
	func disconnect()
	func on(_ event: String, callback: @escaping ([Any]) -> Void)
	func handleEvent(_ event: String, with data: [Any])
	func sendMessage(_ message: String, to channel: String, tts: Bool)
}
