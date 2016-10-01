struct DiscordEventHandler {
	let event: String
	let callback: ([Any]) -> Void

	func executeCallback(with data: [Any]) {
		callback(data)
	}
}