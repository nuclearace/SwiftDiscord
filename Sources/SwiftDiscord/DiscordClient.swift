import Foundation

open class DiscordClient : DiscordClientSpec, DiscordDispatchEventHandler {
	public let token: String

	public var engine: DiscordEngineSpec?

	public private(set) var guilds = [String: DiscordGuild]()
	public private(set) var relationships = [[String: Any]]()
	public private(set) var user: DiscordUser?

	private(set) var handleQueue = DispatchQueue.main

	private var handlers = [String: DiscordEventHandler]()

	public required init(token: String) {
		self.token = token
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

	open func handleEngineDispatch(event: DiscordDispatchEvent, data: DiscordGatewayPayloadData) {
		handleQueue.async {
			self.handleDispatch(event: event, data: data)
		}
	}

	open func handleEngineEvent(_ event: String, with data: [Any]) {
		handleEvent(event, with: data)
	}

	open func handleGuildEmojiUpdate(with data: [String: Any]) {
		guard let guildId = data["guild_id"] as? String else { return }
		guard let emojis = data["emojis"] as? [[String: Any]] else { return }

		guilds[guildId]?.emojis = DiscordEmoji.emojisFromArray(emojis)

		handleEvent("emojiUpdate", with: [guildId, guilds[guildId]?.emojis ?? [:]])
	}

	open func handleGuildMemberAdd(with data: [String: Any]) {
		guard let guildId = data["guild_id"] as? String else { return }

		let guildMember = DiscordGuildMember(guildMemberObject: data)

		guilds[guildId]?.members[guildMember.user.id] = guildMember

		handleEvent("guildMemberAdd", with: [guildId, guildMember])
	}

	open func handleGuildMemberRemove(with data: [String: Any]) {
		guard let guildId = data["guild_id"] as? String else { return }
		guard let user = data["user"] as? [String: Any], let id = user["id"] as? String else { return }

		let removedGuildMember = guilds[guildId]?.members.removeValue(forKey: id)

		handleEvent("guildMemberRemove", with: [guildId, removedGuildMember])
	}

	open func handleGuildMemberUpdate(with data: [String: Any]) {
		guard let guildId = data["guild_id"] as? String else { return }
		guard let user = data["user"] as? [String: Any], let roles = data["roles"] as? [String], 
			let id = user["id"] as? String else { return }

		guilds[guildId]?.members[id]?.roles = roles

		handleEvent("guildMemberUpdate", with: [guildId, user, roles])
	}

	open func handleGuildRoleCreate(with data: [String: Any]) {
		guard let guildId = data["guild_id"] as? String else { return }
		guard let roleObject = data["role"] as? [String: Any] else { return }

		let role = DiscordRole(roleObject: roleObject)

		guilds[guildId]?.roles[role.id] = role

		handleEvent("guildRoleCreate", with: [guildId, role])
	}

	open func handleGuildRoleRemove(with data: [String: Any]) {
		guard let guildId = data["guild_id"] as? String else { return }
		guard let roleId = data["role_id"] as? String else { return }

		let removedRole = guilds[guildId]?.roles.removeValue(forKey: roleId)

		handleEvent("guildRoleRemove", with: [guildId, removedRole])
	}

	open func handleGuildRoleUpdate(with data: [String: Any]) {
		// Functionally the same as adding
		guard let guildId = data["guild_id"] as? String else { return }
		guard let roleObject = data["role"] as? [String: Any] else { return }

		let role = DiscordRole(roleObject: roleObject)

		guilds[guildId]?.roles[role.id] = role

		handleEvent("guildRoleUpdate", with: [guildId, role])
	}

	open func handleGuildUpdate(with data: [String: Any]) {
		guard let guildId = data["id"] as? String else { return }

		let updatedGuild = self.guilds[guildId]?.updateGuild(with: data)

		handleEvent("guildUpdate", with: [guildId, updatedGuild])
	}

	open func handlePresenceUpdate(with data: [String: Any]) {
		guard let guildId = data["guild_id"] as? String else { return }

		let presence = DiscordPresence(presenceObject: data, guildId: guildId)

		self.guilds[guildId]?.presences[presence.user.id] = presence

		handleEvent("presenceUpdate", with: [guildId, presence])
	}

	open func handleReady(with data: [String: Any]) {
		if let user = data["user"] as? [String: Any] {
			self.user = DiscordUser(userObject: user)
		}

		if let guilds = data["guilds"] as? [[String: Any]] {
			self.guilds = DiscordGuild.guildsFromArray(guilds)
		}

		if let relationships = data["relationships"] as? [[String: Any]] {
			self.relationships = relationships
		}

		handleEvent("connect", with: [data])
	}

	open func on(_ event: String, callback: @escaping ([Any]) -> Void) {
		handlers[event] = DiscordEventHandler(event: event, callback: callback)
	}
}
