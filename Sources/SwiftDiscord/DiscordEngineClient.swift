public protocol DiscordEngineClient {
	func handleEngineEvent(_ event: String, with data: [Any])
}

extension DiscordEngineClient {
	func handleEngineEvent(_ event: String, with data: [Any]) {
		print("Got engine event \(event) with \(data)")
	}
}
