public protocol DiscordEngineClient {
	func handleEngineDispatch(event: DiscordDispatchEvent, data: DiscordGatewayPayloadData)
	func handleEngineEvent(_ event: String, with data: [Any])
}

extension DiscordEngineClient {
	func handleEngineEvent(_ event: String, with data: [Any]) {
		print("Got engine event \(event) with \(data)")
	}
}
