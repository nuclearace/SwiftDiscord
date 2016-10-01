import Foundation
import Starscream

public protocol DiscordEngineSpec : class {
	weak var client: DiscordClientSpec? { get }

	var websocket: WebSocket? { get }

	init(client: DiscordClientSpec)

	func connect()
	func disconnect()
}
