public protocol DiscordDispatchEventHandler : DiscordClientSpec {
	func handleDispatch(event: DiscordDispatchEvent, data: DiscordGatewayPayloadData)
	func handleGuildEmojiUpdate(with data: [String: Any])
	func handleGuildMemberAdd(with data: [String: Any])
	func handleGuildMemberRemove(with data: [String: Any])
	func handleReady(with data: [String: Any])
}

public extension DiscordDispatchEventHandler {
	func handleDispatch(event: DiscordDispatchEvent, data: DiscordGatewayPayloadData) {
		switch (event, data) {
		case let (.messageCreate, .object(data)):
			handleEvent("message", with: [DiscordMessage(messageObject: data)])
		case let (.messageUpdate, .object(data)):
			handleEvent("messageUpdate", with: [data])
		case let (.messageDelete, .object(data)):
			handleEvent("messageDelete", with: [data])
		case let (.messageDeleteBulk, .object(data)):
			handleEvent("messageDeleteBulk", with: [data])
		case let (.guildMemberAdd, .object(data)):
			handleGuildMemberAdd(with: data)
		case let (.guildMemberRemove, .object(data)):
			handleGuildMemberRemove(with: data)
		case let (.guildEmojisUpdate, .object(data)):
			handleGuildEmojiUpdate(with: data)
		case let (.ready, .object(data)):
			handleReady(with: data)
		default:
			print("Dispatch event went unhandled \(event)\ndelegating to listeners")

			handleEvent(event.rawValue, with: [data])
		}
	}
}
