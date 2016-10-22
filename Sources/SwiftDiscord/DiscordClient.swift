import Foundation

open class DiscordClient : DiscordClientSpec, DiscordDispatchEventHandler, DiscordEndpointConsumer {
	public let token: String

	public var engine: DiscordEngineSpec?
	public var handleQueue = DispatchQueue.main
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

	// crunchQueue should be used for tasks would block the handleQueue for too long
	// DO NOT TOUCH ANY PROPERTIES WHILE ON THIS QUEUE. REENTER THE HANDLEQUEUE
	private let crunchQueue = DispatchQueue(label: "crunchQueue", attributes: [])

	private var handlers = [String: DiscordEventHandler]()
	private var joiningVoiceChannel = false
	private var voiceServerInformation: [String: Any]?

	public required init(token: String) {
		self.token = token
	}

	open func attachEngine() {
		// print("Attaching engine")

		engine = DiscordEngine(client: self)

		on("engine.disconnect") {[weak self] data in
			self?.handleEvent("disconnect", with: data)
		}
	}

	open func connect() {
		// print("DiscordClient connecting")

		attachEngine()

		engine?.connect()
	}

	open func disconnect() {
		// print("DiscordClient: Disconnecting")

		connected = false

		engine?.disconnect()
	}

	// Handling

	open func on(_ event: String, callback: @escaping ([Any]) -> Void) {
		handlers[event] = DiscordEventHandler(event: event, callback: callback)
	}

	open func handleChannelCreate(with data: [String: Any]) {
		let channel = DiscordGuildChannel(guildChannelObject: data)

		guilds[channel.guildId]?.channels[channel.id] = channel

		handleEvent("channelCreate", with: [channel.guildId, channel])
	}

	open func handleChannelDelete(with data: [String: Any]) {
		guard let guildId = data["guild_id"] as? String else { return }
		guard let channelId = data["id"] as? String else { return }

		guard let removedChannel = guilds[guildId]?.channels.removeValue(forKey: channelId) else { return }

		handleEvent("channelDelete", with: [guildId, removedChannel])
	}

	open func handleChannelUpdate(with data: [String: Any]) {
		let channel = DiscordGuildChannel(guildChannelObject: data)

		guilds[channel.guildId]?.channels[channel.id] = channel

		handleEvent("channelUpdate", with: [channel.guildId, channel])
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
		crunchQueue.async {
			let guild = DiscordGuild(guildObject: data)

			self.handleQueue.async {
				self.guilds[guild.id] = guild

				self.handleEvent("guildCreate", with: [guild.id, guild])
			}
		}
	}

	open func handleGuildDelete(with data: [String: Any]) {
		guard let guildId = data["id"] as? String else { return }
		guard let removedGuild = guilds.removeValue(forKey: guildId) else { return }

		handleEvent("guildDelete", with: [guildId, removedGuild])
	}

	open func handleGuildEmojiUpdate(with data: [String: Any]) {
		guard let guildId = data["guild_id"] as? String else { return }
		guard let emojis = data["emojis"] as? [[String: Any]] else { return }

		guilds[guildId]?.emojis = DiscordEmoji.emojisFromArray(emojis)

		handleEvent("guildEmojisUpdate", with: [guildId, guilds[guildId]?.emojis ?? [:]])
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

		guard let removedGuildMember = guilds[guildId]?.members.removeValue(forKey: id) else { return }

		handleEvent("guildMemberRemove", with: [guildId, removedGuildMember])
	}

	open func handleGuildMemberUpdate(with data: [String: Any]) {
		guard let guildId = data["guild_id"] as? String else { return }
		guard let user = data["user"] as? [String: Any], let roles = data["roles"] as? [String],
			let id = user["id"] as? String else { return }

		guilds[guildId]?.members[id]?.roles = roles

		handleEvent("guildMemberUpdate", with: [guildId, user, roles])
	}

	open func handleGuildMembersChunk(with data: [String: Any]) {
		guard let guildId = data["guild_id"] as? String else { return }
		guard let members = data["members"] as? [[String: Any]] else { return }

		crunchQueue.async {
			let guildMembers = DiscordGuildMember.guildMembersFromArray(members)

			self.handleQueue.async {
				guard var guild = self.guilds[guildId] else { return }

				for (memberId, member) in guildMembers {
					guild.members[memberId] = member
				}

				self.guilds[guildId] = guild

				self.handleEvent("guildMembersChunk", with: [guildId, guildMembers])
			}
		}
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

		guard let removedRole = guilds[guildId]?.roles.removeValue(forKey: roleId) else { return }

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

		guard let updatedGuild = self.guilds[guildId]?.updateGuild(with: data) else { return }

		handleEvent("guildUpdate", with: [guildId, updatedGuild])
	}

	open func handlePresenceUpdate(with data: [String: Any]) {
		guard let guildId = data["guild_id"] as? String else { return }

		let presence = DiscordPresence(presenceObject: data, guildId: guildId)

		self.guilds[guildId]?.presences[presence.user.id] = presence

		handleEvent("presenceUpdate", with: [guildId, presence])
	}

	open func handleReady(with data: [String: Any]) {
		guard let milliseconds = data["heartbeat_interval"] as? Int else {
			handleEvent("disconnect", with: ["Failed to get heartbeat"])

			return
		}

		engine?.startHeartbeat(seconds: milliseconds / 1000)

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
		self.voiceServerInformation = data

		if self.joiningVoiceChannel {
			// print("got voice server \(data)")
			self.startVoiceConnection()
		}
	}

	open func handleVoiceStateUpdate(with data: [String: Any]) {
		// Only care about our state right now
		guard data["user_id"] as? String == self.user?.id else { return }
		guard let guildId = data["guild_id"] as? String else { return }

		self.voiceState = DiscordVoiceState(voiceStateObject: data, guildId: guildId)

		if self.joiningVoiceChannel {
			// print("Got voice state \(data)")
			self.startVoiceConnection()
		}
	}

	private func guildForChannel(_ channelId: String) -> DiscordGuild? {
		for (_, guild) in guilds where guild.channels[channelId] != nil {
			return guild
		}

		return nil
	}

	open func joinVoiceChannel(_ channelId: String, callback: @escaping (String) -> Void) {
		guard let guild = guildForChannel(channelId), let channel = guild.channels[channelId],
				channel.type == .voice else {
			callback("invalid channel")

			return
		}

		self.joiningVoiceChannel = true

		self.engine?.sendGatewayPayload(DiscordGatewayPayload(code: .gateway(.voiceStatusUpdate),
			payload: .object([
				"guild_id": guild.id,
				"channel_id": channel.id,
				"self_mute": false,
				"self_deaf": false
				])
			)
		)
	}

	open func leaveVoiceChannel(_ channelId: String) {
		guard let guild = guildForChannel(channelId), let channel = guild.channels[channelId],
				channel.type == .voice else {
			return
		}

		self.voiceEngine?.disconnect()
		self.voiceEngine = nil

		self.engine?.sendGatewayPayload(DiscordGatewayPayload(code: .gateway(.voiceStatusUpdate),
			payload: .object([
				"guild_id": guild.id,
				"channel_id": NSNull(),
				"self_mute": false,
				"self_deaf": false
				])
			)
		)

		self.joiningVoiceChannel = false
	}

	open func requestAllUsers(on guildId: String) {
		let requestObject: [String: Any] = [
			"guild_id": guildId,
			"query": "",
			"limit": 0
		]

		engine?.sendGatewayPayload(DiscordGatewayPayload(code: .gateway(.requestGuildMembers),
			payload: .object(requestObject)))
	}

	open func setPresence(_ presence: [String: Any]) {
		engine?.sendGatewayPayload(DiscordGatewayPayload(code: .gateway(.statusUpdate), payload: .object(presence)))
	}

	private func startVoiceConnection() {
		// We need both to start the connection
		guard voiceState != nil && voiceServerInformation != nil else {
			return
		}

		// Reuse a previous engine's encoder if possible
		voiceEngine = DiscordVoiceEngine(client: self, voiceServerInformation: voiceServerInformation!,
			encoder: voiceEngine?.encoder, secret: voiceEngine?.secret)

		// print("Connecting voice engine")

		voiceEngine?.connect()
	}
}
