import Foundation

protocol DiscordEngineGatewayHandling : DiscordEngineSpec, DiscordEngineHeartbeatable {
	func handleDispatch(_ payload: DiscordGatewayPayload)
}

extension DiscordEngineGatewayHandling {
	func handleDispatch(_ payload: DiscordGatewayPayload) {
		guard let type = payload.name, let event = DiscordDispatchEvent(rawValue: type) else {
			error()

			return
		}

		if event == .ready, case let DiscordGatewayPayloadData.object(payloadData) = payload.payload, 
			let milliseconds = payloadData["heartbeat_interval"] as? Int {
				startHeartbeat(seconds: milliseconds / 1000)
		} else {
			fatalError("Failed to start our heartbeat")
		}

		client?.handleEngineDispatch(event: event, data: payload.payload)
	}
}
