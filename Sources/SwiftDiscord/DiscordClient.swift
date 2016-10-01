import Foundation

open class DiscordClient : DiscordClientSpec {
	public let token: String

	public var engine: DiscordEngineSpec?

	public private(set) var user: DiscordUser?

	private(set) var handleQueue = DispatchQueue.main

	private var handlers = [String: DiscordEventHandler]()

	public required init(token: String) {
		self.token = token

		on("engine.connect") {[unowned self] data in
			print("Engine connected")
		}

		on("engine.disconnect") {[unowned self] data in
			print("Engine disconnected")
		}

		on("engine.user") {[unowned self] data in
			guard let user = data[0] as? [String: Any] else { return }
			print("DiscordClient: setting user")

			let avatar = user["avatar"] as? String ?? ""
			let bot = user["bot"] as? Bool ?? false
			let discriminator = user["discriminator"] as? String ?? ""
			let email = user["email"] as? String ?? ""
			let id = user["id"] as? String ?? ""
			let mfaEnabled = user["mfa_enabled"] as? Bool ?? false
			let username = user["username"] as? String ?? ""
			let verified = user["verified"] as? Bool ?? false

			self.user = DiscordUser(avatar: avatar, bot: bot, discriminator: discriminator, email: email, id: id,
				mfaEnabled: mfaEnabled, username: username, verified: verified)

			print(self.user)
		}
	}

	open func attachEngine() {
		print("Attaching engine")

		engine = DiscordEngine(client: self)
	}

	open func connect() {
		print("DiscordClient connecting")

		attachEngine()

		engine?.connect()
	}

	open func disconnect() {
		print("DiscordClient: Disconnecting")

		engine?.disconnect()
	}

	open func handleEvent(_ event: String, with data: [Any]) {
		handleQueue.async {
			self.handlers[event]?.executeCallback(with: data)
		}
	}

	open func handleEngineEvent(_ event: String, with data: [Any]) {
		handleEvent(event, with: data)
	}

	open func on(_ event: String, callback: @escaping ([Any]) -> Void) {
		handlers[event] = DiscordEventHandler(event: event, callback: callback)
	}
}
