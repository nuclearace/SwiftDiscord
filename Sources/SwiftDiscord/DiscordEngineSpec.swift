import Foundation
import Starscream

public protocol DiscordEngineSpec : class {
	weak var client: DiscordClientSpec? { get }

	var lastSequenceNumber: Int { get }
	var websocket: WebSocket? { get }

	init(client: DiscordClientSpec)

	func connect()
	func error()
	func disconnect()
	func sendGatewayPayload(_ payload: DiscordGatewayPayload)
}

public extension DiscordEngineSpec {
	func sendGatewayPayload(_ payload: DiscordGatewayPayload) {
		guard let payloadString = payload.createPayloadString() else {
			error()

			return
		}

		websocket?.write(string: payloadString)
	}
}
