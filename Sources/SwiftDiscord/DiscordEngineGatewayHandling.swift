import Foundation

protocol DiscordEngineGatewayHandling : DiscordEngineSpec, DiscordEngineHeartbeatable {
	func handleDispatch(_ payload: DiscordGatewayPayload)
}

extension DiscordEngineGatewayHandling {
	func handleDispatch(_ payload: DiscordGatewayPayload) {
		guard let type = payload.name, let event = DiscordDispatchEvent(rawValue: type) else {
			error(message: "Error trying to create dispatch info \(payload)")

			return
		}

		client?.handleEngineDispatch(event: event, data: payload.payload)
	}
}
