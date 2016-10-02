import Foundation

open class DiscordClient : DiscordClientSpec {
	public let token: String

	public var engine: DiscordEngineSpec?

	public private(set) var guilds = [String: DiscordGuild]()
	public private(set) var user: DiscordUser?

	private(set) var handleQueue = DispatchQueue.main

	private var handlers = [String: DiscordEventHandler]()

	public required init(token: String) {
		self.token = token

		on("engine.connect") {[weak self] data in
			print("Engine connected")
		}

		on("engine.disconnect") {[weak self] data in
			print("Engine disconnected")
		}

		on("engine.user") {[weak self] data in
			guard let user = data[0] as? [String: Any] else { return }

			print("DiscordClient: setting user")

			self?.user = DiscordUser.userFromDictionary(user)
		}

		on("engine.guilds") {[weak self] data in
			guard let guilds = data[0] as? [[String: Any]] else { return }

			print("DiscordClient: setting guilds")

			self?.guilds = DiscordGuild.guildsFromArray(guilds)

			// print(self!.guilds["201533018215677953"]!.joinedAt)
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
