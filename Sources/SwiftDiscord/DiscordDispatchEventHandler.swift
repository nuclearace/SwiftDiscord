public protocol DiscordDispatchEventHandler : DiscordClientSpec {
	func handleDispatch(event: DiscordDispatchEvent, data: DiscordGatewayPayloadData)
	func handleReady(with data: [String: Any])
}

public extension DiscordDispatchEventHandler {
	func handleDispatch(event: DiscordDispatchEvent, data: DiscordGatewayPayloadData) {
		switch (event, data) {
		case let (.ready, .object(data)):
			handleReady(with: data)
		default:
			return
		}
	}
}
