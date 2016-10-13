import Foundation

open class DiscordClient : DiscordClientSpec, DiscordDispatchEventHandler {
	public let token: String

	public var engine: DiscordEngineSpec?
	public var voiceEngine: DiscordVoiceEngineSpec?

	public var isBot: Bool {
		guard let user = self.user else { return false }

		return user.bot
	}

	public private(set) var connected = false
	public private(set) var guilds = [String: DiscordGuild]()
	public private(set) var relationships = [[String: Any]]()
	public private(set) var user: DiscordUser?
	public private(set) var voiceState: DiscordVoiceState?

	private(set) var handleQueue = DispatchQueue.main

	private var handlers = [String: DiscordEventHandler]()
	private var joiningVoiceChannel = false
	private var voiceQueue = DispatchQueue(label: "voiceQueue")
	private var voiceServerInformation: [String: Any]?

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

		connected = false
		
		engine?.disconnect()
		voiceEngine?.disconnect()
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

	open func handleGuildCreate(with data: [String: Any]) {
		let guild = DiscordGuild(guildObject: data)

		guilds[guild.id] = guild

		handleEvent("guildCreate", with: [guild])
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

		connected = true
		handleEvent("connect", with: [data])
	}

	open func handleVoiceServerUpdate(with data: [String: Any]) {
		voiceQueue.async {
			self.voiceServerInformation = data

			if self.joiningVoiceChannel {
				// print("got voice server \(data)")
				self.startVoiceConnection()
			}
		}
	}

	open func handleVoiceStateUpdate(with data: [String: Any]) {
		voiceQueue.async {
			// Only care about our state right now
			guard data["user_id"] as? String == self.user?.id else { return }
			guard let guildId = data["guild_id"] as? String else { return }

			self.voiceState = DiscordVoiceState(voiceStateObject: data, guildId: guildId)

			if self.joiningVoiceChannel {
				// print("Got voice state \(data)")
				self.startVoiceConnection()
			}
		}
	}

	open func getMessages(for channelId: String, options: [DiscordEndpointOptions.GetMessage] = [],
		callback: @escaping ([DiscordMessage]) -> Void) {
		DiscordEndpoint.getMessages(for: channelId, with: token, options: options,  isBot: isBot, callback: callback)
	}

	private func guildForChannel(_ channelId: String) -> DiscordGuild? {
		for (_, guild) in guilds where guild.channels[channelId] != nil {
			return guild
		}

		return nil
	}

	open func joinVoiceChannel(_ channelId: String, callback: @escaping (String) -> Void) {
		print(guilds)
		guard let guild = guildForChannel(channelId), let channel = guild.channels[channelId], channel.type == .voice else {
			callback("invalid channel")

			return
		}

		// begin async voice connection establishment
		voiceQueue.async {
			self.joiningVoiceChannel = true

			self.engine?.sendGatewayPayload(DiscordGatewayPayload(code: .gateway(.voiceStatusUpdate), payload: .object([
				"guild_id": guild.id,
				"channel_id": channel.id,
				"self_mute": false,
				"self_deaf": false
			])))
		}
	}

	open func on(_ event: String, callback: @escaping ([Any]) -> Void) {
		handlers[event] = DiscordEventHandler(event: event, callback: callback)
	}

	open func sendMessage(_ message: String, to channelId: String, tts: Bool = false) {
		guard connected else { return }

		DiscordEndpoint.sendMessage(message, with: token, to: channelId, tts: tts, isBot: isBot)
	}

	private func startVoiceConnection() {
		// We need both to start the connection
		guard voiceState != nil && voiceServerInformation != nil else {
			return
		}

		// Reuse a previous engine's encoder if possible
		voiceEngine = DiscordVoiceEngine(client: self, voiceServerInformation: voiceServerInformation!, 
			encoder: voiceEngine?.encoder, secret: voiceEngine?.secret)

		print("Connecting voice engine")

		voiceEngine?.connect()
	}
}
