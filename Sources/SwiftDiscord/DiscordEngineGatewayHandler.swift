import Foundation

protocol DiscordEngineGatewayHandler : DiscordEngineSpec {
	func handleDispatch(_ payload: DiscordGatewayPayload)
}

extension DiscordEngineGatewayHandler {
	func handleDispatch(_ payload: DiscordGatewayPayload) {
		print("Should handle payload")
	}
}
