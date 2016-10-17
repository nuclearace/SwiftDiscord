import Foundation

open class DiscordClient : DiscordClientSpec, DiscordDispatchEventHandler {
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

	private let voiceQueue = DispatchQueue(label: "voiceQueue")

	private var handlers = [String: DiscordEventHandler]()
	private var joiningVoiceChannel = false
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
		let channel = DiscordGuildChannel(guildChannelObject: data)

		guard let removedChannel = guilds[channel.guildId]?.channels.removeValue(forKey: channel.id) else { return }

		handleEvent("channelDelete", with: [channel.guildId, removedChannel])
	}

	open func handleChannelUpdate(with data: [String: Any]) {
		let channel = DiscordGuildChannel(guildChannelObject: data)

		guilds[channel.guildId]?.channels[channel.id] = channel

		print(channel)

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
		voiceQueue.sync {
			self.voiceServerInformation = data

			if self.joiningVoiceChannel {
				// print("got voice server \(data)")
				self.startVoiceConnection()
			}
		}
	}

	open func handleVoiceStateUpdate(with data: [String: Any]) {
		voiceQueue.sync {
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

	// REST api

	open func addPinnedMessage(_ messageId: String, on channelId: String) {
		DiscordEndpoint.addPinnedMessage(messageId, on: channelId, with: token, isBot: isBot)
	}

	open func bulkDeleteMessages(_ messages: [String], on channelId: String) {
		DiscordEndpoint.bulkDeleteMessages(messages, on: channelId, with: token, isBot: isBot)
	}

	open func createInvite(for channelId: String, options: [DiscordEndpointOptions.CreateInvite],
			callback: @escaping (DiscordInvite?) -> Void) {
		DiscordEndpoint.createInvite(for: channelId, options: options, with: token, isBot: isBot, callback: callback)
	}

	open func createGuildChannel(on guildId: String, options: [DiscordEndpointOptions.GuildCreateChannel]) {
		DiscordEndpoint.createGuildChannel(guildId, options: options, with: token, isBot: isBot)
	}

	open func deleteChannel(_ channelId: String) {
		DiscordEndpoint.deleteChannel(channelId, with: token, isBot: isBot)
	}

	open func deleteChannelPermission(_ overwriteId: String, on channelId: String) {
		DiscordEndpoint.deleteChannelPermission(overwriteId, on: channelId, with: token, isBot: isBot)
	}

	open func deleteGuild(_ guildId: String) {
		DiscordEndpoint.deleteGuild(guildId, with: token, isBot: isBot)
	}

	open func deleteMessage(_ messageId: String, on channelId: String) {
		DiscordEndpoint.deleteMessage(messageId, on: channelId, with: token, isBot: isBot)
	}

	open func deletePinnedMessage(_ messageId: String, on channelId: String) {
		DiscordEndpoint.deletePinnedMessage(messageId, on: channelId, with: token, isBot: isBot)
	}

	open func editMessage(_ messageId: String, on channelId: String, content: String) {
		DiscordEndpoint.editMessage(messageId, on: channelId, content: content, with: token, isBot: isBot)
	}

	open func editChannelPermission(_ permissionOverwrite: DiscordPermissionOverwrite, on channelId: String) {
		DiscordEndpoint.editChannelPermission(permissionOverwrite, on: channelId, with: token, isBot: isBot)
	}

	open func getChannel(_ channelId: String, callback: @escaping (DiscordGuildChannel?) -> Void) {
		DiscordEndpoint.getChannel(channelId, with: token, isBot: isBot, callback: callback)
	}

	open func getBotURL(with permissions: [DiscordPermission]) -> URL? {
		guard let user = self.user else { return nil }

		return DiscordOAuthEndpoint.createBotAddURL(for: user, with: permissions)
	}

	open func getGuildChannels(_ guildId: String, callback: @escaping ([DiscordGuildChannel]) -> Void) {
		DiscordEndpoint.getGuildChannels(guildId, with: token, isBot: isBot, callback: callback)
	}

	open func getGuildMember(by id: String, on guildId: String, callback: @escaping (DiscordGuildMember?) -> Void) {
		DiscordEndpoint.getGuildMember(by: id, on: guildId, with: token, isBot: isBot, callback: callback)
	}

	open func getGuildMembers(on guildId: String, options: [DiscordEndpointOptions.GuildGetMembers],
		callback: @escaping ([DiscordGuildMember]) -> Void) {
		DiscordEndpoint.getGuildMembers(on: guildId, options: options, with: token, isBot: isBot, callback: callback)
	}

	open func getInvites(for channelId: String, callback: @escaping ([DiscordInvite]) -> Void) {
		return DiscordEndpoint.getInvites(for: channelId, with: token, isBot: isBot, callback: callback)
	}

	open func getMessages(for channelId: String, options: [DiscordEndpointOptions.GetMessage] = [],
			callback: @escaping ([DiscordMessage]) -> Void) {
		DiscordEndpoint.getMessages(for: channelId, with: token, options: options, isBot: isBot, callback: callback)
	}

	open func getPinnedMessages(for channelId: String, callback: @escaping ([DiscordMessage]) -> Void) {
		DiscordEndpoint.getPinnedMessages(for: channelId, with: token, isBot: isBot, callback: callback)
	}

	open func modifyChannel(_ channelId: String, options: [DiscordEndpointOptions.ModifyChannel]) {
		DiscordEndpoint.modifyChannel(channelId, options: options, with: token, isBot: isBot)
	}

	open func modifyGuild(_ guildId: String, options: [DiscordEndpointOptions.ModifyGuild]) {
		DiscordEndpoint.modifyGuild(guildId, options: options, with: token, isBot: isBot)
	}

	open func modifyGuildChannelPosition(on guildId: String, channelId: String, position: Int) {
		DiscordEndpoint.modifyGuildChannelPosition(on: guildId, channelId: channelId, position: position,
			with: token, isBot: isBot)
	}

	open func sendMessage(_ message: String, to channelId: String, tts: Bool = false) {
		guard connected else { return }

		DiscordEndpoint.sendMessage(message, with: token, to: channelId, tts: tts, isBot: isBot)
	}

	open func triggerTyping(on channelId: String) {
		DiscordEndpoint.triggerTyping(on: channelId, with: token, isBot: isBot)
	}

	private func guildForChannel(_ channelId: String) -> DiscordGuild? {
		for (_, guild) in guilds where guild.channels[channelId] != nil {
			return guild
		}

		return nil
	}

	// Voice

	open func joinVoiceChannel(_ channelId: String, callback: @escaping (String) -> Void) {
		guard let guild = guildForChannel(channelId), let channel = guild.channels[channelId],
				channel.type == .voice else {
			callback("invalid channel")

			return
		}

		// begin async voice connection establishment
		// TODO handle failures
		voiceQueue.async {
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
	}

	open func leaveVoiceChannel(_ channelId: String) {
		guard let guild = guildForChannel(channelId), let channel = guild.channels[channelId],
				channel.type == .voice else {
			return
		}

		voiceQueue.async {
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
