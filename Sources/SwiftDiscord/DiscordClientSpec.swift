import Foundation

public protocol DiscordClientSpec : class, DiscordEngineClient {
	var token: String { get }

	init(token: String)

	func connect()
	func disconnect()
	func on(_ event: String, callback: @escaping ([Any]) -> Void)
}
