import Foundation

protocol DiscordEngineGatewayHandling : DiscordEngineSpec, DiscordEngineHeartbeatable {
	func handleDispatch(_ payload: DiscordGatewayPayload)
}

extension DiscordEngineGatewayHandling {
	func handleDispatch(_ payload: DiscordGatewayPayload) {
		if let type = payload.name, type == "READY" {
			handleReady(payload)

			return
		}

		print("Should handle payload")
	}

	func handleReady(_ payload: DiscordGatewayPayload) {
		// Setup the heartbeat
		guard case let DiscordGatewayPayloadData.object(payloadData) = payload.payload, 
			let milliseconds = payloadData["heartbeat_interval"] as? Int else { 
				error()

				return
		}

		startHeartbeat(seconds: milliseconds / 1000)

		// Tell the client about their user settings
		if let user = payloadData["user"] as? [String: Any] {
			client?.handleEngineEvent("engine.user", with: [user])
		}

		// Tell the client about their guilds
		if let guilds = payloadData["guilds"] as? [Any] {
			client?.handleEngineEvent("engine.guilds", with: [guilds])
		}
	}
}
