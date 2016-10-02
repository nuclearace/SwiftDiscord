public protocol DiscordDispatchEventHandler : DiscordClientSpec {
	func handleDispatch(event: DiscordDispatchEvent, data: DiscordGatewayPayloadData)
	func handleReady(with data: [String: Any])
}

public extension DiscordDispatchEventHandler {
	func handleDispatch(event: DiscordDispatchEvent, data: DiscordGatewayPayloadData) {
		switch (event, data) {
		case let (.messageCreate, .object(data)):
			handleEvent("message", with: [DiscordMessage(messageObject: data)])
		case let (.messageUpdate, .object(data)):
			print("handle message updated")
		case let (.messageDelete, .object(data)):
			print("handle message deleted")
		case let (.messageDeleteBulk, .object(data)):
			print("handle message delete bulk")
		case let (.ready, .object(data)):
			handleReady(with: data)
		default:
			print("Dispatch event went unhandled \(event)")
		}
	}
}
