import Foundation

open class DiscordClient : DiscordClientSpec {
	public let token: String

	public var engine: DiscordEngineSpec?

	private(set) var handleQueue = DispatchQueue.main

	private var handlers = [DiscordEventHandler]()

	public required init(token: String) {
		self.token = token

		on("engine.connect") {[unowned self] data in
			print("Engine connected")
		}

		on("engine.disconnect") {[unowned self] data in
			print("Engine disconnected")
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
			for handler in self.handlers where handler.event == event {
				handler.executeCallback(with: data)
			}
		}
	}

	open func handleEngineEvent(_ event: String, with data: [Any]) {
		handleEvent(event, with: data)
	}

	open func on(_ event: String, callback: @escaping ([Any]) -> Void) {
		handlers.append(DiscordEventHandler(event: event, callback: callback))
	}
}
