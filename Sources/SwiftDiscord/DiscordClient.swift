// The MIT License (MIT)
// Copyright (c) 2016 Erik Little

// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated
// documentation files (the "Software"), to deal in the Software without restriction, including without
// limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the
// Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

// The above copyright notice and this permission notice shall be included in all copies or substantial portions of the
// Software.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING
// BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO
// EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
// ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
// DEALINGS IN THE SOFTWARE.

import Foundation
import Dispatch

open class DiscordClient : DiscordClientSpec, DiscordDispatchEventHandler, DiscordEndpointConsumer {
	public let token: String

	public var engine: DiscordEngineSpec?
	public var handleQueue = DispatchQueue.main
    #if !os(iOS)
	public var voiceEngine: DiscordVoiceEngineSpec?
    #endif
	public var onVoiceData: (DiscordVoiceData) -> Void = {_ in }

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
	private let crunchQueue = DispatchQueue(label: "crunchQueue")
	private let logType = "DiscordClient"
	private let voiceQueue = DispatchQueue(label: "voiceQueue")

	private var handlers = [String: DiscordEventHandler]()
	private var joiningVoiceChannel = false
	private var voiceServerInformation: [String: Any]?

	public required init(token: String, configuration: [DiscordClientOption] = []) {
		self.token = token

		for config in configuration {
			switch config {
			case let .handleQueue(queue):
				handleQueue = queue
			case let .log(level):
				DefaultDiscordLogger.Logger.level = level
			case let .logger(logger):
				DefaultDiscordLogger.Logger = logger
			}
		}
	}

	open func attachEngine() {
		DefaultDiscordLogger.Logger.log("Attaching engine", type: logType)

		engine = DiscordEngine(client: self)

		on("engine.disconnect") {[weak self] data in
			self?.handleEvent("disconnect", with: data)
		}
	}

	open func connect() {
		DefaultDiscordLogger.Logger.log("Connecting", type: logType)

		attachEngine()

		engine?.connect()
	}

	open func disconnect() {
		DefaultDiscordLogger.Logger.log("Disconnecting", type: logType)

		connected = false

		engine?.disconnect()

        #if !os(iOS)
		voiceEngine?.disconnect()
        #endif
	}

	// Handling

	open func on(_ event: String, callback: @escaping ([Any]) -> Void) {
		handlers[event] = DiscordEventHandler(event: event, callback: callback)
	}

	open func handleChannelCreate(with data: [String: Any]) {
		DefaultDiscordLogger.Logger.log("Handling channel create", type: logType)

		let channel = DiscordGuildChannel(guildChannelObject: data)

		DefaultDiscordLogger.Logger.verbose("Created channel: %@", type: logType, args: channel)

		guilds[channel.guildId]?.channels[channel.id] = channel

		handleEvent("channelCreate", with: [channel.guildId, channel])
	}

	open func handleChannelDelete(with data: [String: Any]) {
		DefaultDiscordLogger.Logger.log("Handling channel delete", type: logType)

		guard let guildId = data["guild_id"] as? String else { return }
		guard let channelId = data["id"] as? String else { return }

		guard let removedChannel = guilds[guildId]?.channels.removeValue(forKey: channelId) else { return }

		DefaultDiscordLogger.Logger.verbose("Removed channel: %@", type: logType, args: removedChannel)

		handleEvent("channelDelete", with: [guildId, removedChannel])
	}

	open func handleChannelUpdate(with data: [String: Any]) {
		DefaultDiscordLogger.Logger.log("Handling channel update", type: logType)

		let channel = DiscordGuildChannel(guildChannelObject: data)

		DefaultDiscordLogger.Logger.verbose("Updated channel: %@", type: logType, args: channel)

		guilds[channel.guildId]?.channels[channel.id] = channel

		handleEvent("channelUpdate", with: [channel.guildId, channel])
	}

	open func handleEvent(_ event: String, with data: [Any]) {
		handleQueue.async {
			self.handlers[event]?.executeCallback(with: data)
		}
	}

	open func handleEngineDispatch(_ payload: DiscordGatewayPayload) {
		guard let type = payload.name, let event = DiscordDispatchEvent(rawValue: type) else {
			DefaultDiscordLogger.Logger.error("Could not create dispatch event %@", type: logType, args: payload)

			return
		}

		handleQueue.async {
			self.handleDispatch(event: event, data: payload.payload)
		}
	}

	open func handleEngineEvent(_ event: String, with data: [Any]) {
		handleEvent(event, with: data)
	}

	open func handleGuildCreate(with data: [String: Any]) {
		DefaultDiscordLogger.Logger.log("Handling guild create", type: logType)

		let guild = DiscordGuild(guildObject: data)

		DefaultDiscordLogger.Logger.verbose("Created guild: %@", type: self.logType, args: guild)

		guilds[guild.id] = guild

		handleEvent("guildCreate", with: [guild.id, guild])
	}

	open func handleGuildDelete(with data: [String: Any]) {
		DefaultDiscordLogger.Logger.log("Handling guild delete", type: logType)

		guard let guildId = data["id"] as? String else { return }

		guard let removedGuild = guilds.removeValue(forKey: guildId) else { return }

		DefaultDiscordLogger.Logger.verbose("Removed guild: %@", type: logType, args: removedGuild)

		handleEvent("guildDelete", with: [guildId, removedGuild])
	}

	open func handleGuildEmojiUpdate(with data: [String: Any]) {
		DefaultDiscordLogger.Logger.log("Handling guild emoji update", type: logType)

		guard let guildId = data["guild_id"] as? String else { return }
		guard let emojis = data["emojis"] as? [[String: Any]] else { return }

		let discordEmojis = DiscordEmoji.emojisFromArray(emojis)

		DefaultDiscordLogger.Logger.verbose("Created guild emojis: %@", type: logType, args: discordEmojis)

		guilds[guildId]?.emojis = discordEmojis

		handleEvent("guildEmojisUpdate", with: [guildId, discordEmojis])
	}

	open func handleGuildMemberAdd(with data: [String: Any]) {
		DefaultDiscordLogger.Logger.log("Handling guild member add", type: logType)

		guard let guildId = data["guild_id"] as? String else { return }

		let guildMember = DiscordGuildMember(guildMemberObject: data)

		DefaultDiscordLogger.Logger.verbose("Created guild member: %@", type: logType, args: guildMember)

		guilds[guildId]?.members[guildMember.user.id] = guildMember

		handleEvent("guildMemberAdd", with: [guildId, guildMember])
	}

	open func handleGuildMemberRemove(with data: [String: Any]) {
		DefaultDiscordLogger.Logger.log("Handling guild member remove", type: logType)

		guard let guildId = data["guild_id"] as? String else { return }
		guard let user = data["user"] as? [String: Any], let id = user["id"] as? String else { return }

		guard let removedGuildMember = guilds[guildId]?.members.removeValue(forKey: id) else { return }

		DefaultDiscordLogger.Logger.verbose("Removed guild member: %@", type: logType, args: removedGuildMember)

		handleEvent("guildMemberRemove", with: [guildId, removedGuildMember])
	}

	open func handleGuildMemberUpdate(with data: [String: Any]) {
		DefaultDiscordLogger.Logger.log("Handling guild member update", type: logType)

		guard let guildId = data["guild_id"] as? String else { return }
		guard let user = data["user"] as? [String: Any], let roles = data["roles"] as? [String],
			let id = user["id"] as? String else { return }

		guilds[guildId]?.members[id]?.roles = roles

		// DefaultDiscordLogger.Logger.verbose("Updated guild member: %@", type: logType,
		// 	args: guilds[guildId]?.members[id])

		handleEvent("guildMemberUpdate", with: [guildId, user, roles])
	}

	open func handleGuildMembersChunk(with data: [String: Any]) {
		DefaultDiscordLogger.Logger.log("Handling guild members chunk", type: logType)

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
		DefaultDiscordLogger.Logger.log("Handling guild role create", type: logType)

		guard let guildId = data["guild_id"] as? String else { return }
		guard let roleObject = data["role"] as? [String: Any] else { return }

		let role = DiscordRole(roleObject: roleObject)

		DefaultDiscordLogger.Logger.verbose("Created role: %@", type: logType, args: role)

		guilds[guildId]?.roles[role.id] = role

		handleEvent("guildRoleCreate", with: [guildId, role])
	}

	open func handleGuildRoleRemove(with data: [String: Any]) {
		DefaultDiscordLogger.Logger.log("Handling guild role remove", type: logType)

		guard let guildId = data["guild_id"] as? String else { return }
		guard let roleId = data["role_id"] as? String else { return }

		guard let removedRole = guilds[guildId]?.roles.removeValue(forKey: roleId) else { return }

		DefaultDiscordLogger.Logger.verbose("Removed role: %@", type: logType, args: removedRole)

		handleEvent("guildRoleRemove", with: [guildId, removedRole])
	}

	open func handleGuildRoleUpdate(with data: [String: Any]) {
		DefaultDiscordLogger.Logger.log("Handling guild role update", type: logType)

		// Functionally the same as adding
		guard let guildId = data["guild_id"] as? String else { return }
		guard let roleObject = data["role"] as? [String: Any] else { return }

		let role = DiscordRole(roleObject: roleObject)

		DefaultDiscordLogger.Logger.verbose("Updated role: %@", type: logType, args: role)

		guilds[guildId]?.roles[role.id] = role

		handleEvent("guildRoleUpdate", with: [guildId, role])
	}

	open func handleGuildUpdate(with data: [String: Any]) {
		DefaultDiscordLogger.Logger.log("Handling guild update", type: logType)

		guard let guildId = data["id"] as? String else { return }

		guard let updatedGuild = self.guilds[guildId]?.updateGuild(with: data) else { return }

		DefaultDiscordLogger.Logger.verbose("Updated guild: %@", type: logType, args: updatedGuild)

		handleEvent("guildUpdate", with: [guildId, updatedGuild])
	}

	open func handleMessageCreate(with data: [String: Any]) {
		DefaultDiscordLogger.Logger.log("Handling message create", type: logType)

		let message = DiscordMessage(messageObject: data)

		DefaultDiscordLogger.Logger.verbose("Message: %@", type: logType, args: message)

		handleEvent("messageCreate", with: [message])
	}

	open func handlePresenceUpdate(with data: [String: Any]) {
		DefaultDiscordLogger.Logger.log("Handling presence update", type: logType)

		guard let guildId = data["guild_id"] as? String else { return }
		guard let user = data["user"] as? [String: Any] else { return }
		guard let userId = user["id"] as? String else { return }

		var presence = guilds[guildId]?.presences[userId]

		if presence != nil {
			presence!.updatePresence(presenceObject: data)
		} else {
			presence = DiscordPresence(presenceObject: data, guildId: guildId)
		}

		DefaultDiscordLogger.Logger.debug("Updated presence: %@", type: logType, args: presence!)

		guilds[guildId]?.presences[userId] = presence!

		handleEvent("presenceUpdate", with: [guildId, presence!])
	}

	open func handleReady(with data: [String: Any]) {
		DefaultDiscordLogger.Logger.log("Handling ready", type: logType)

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

	open func handleVoiceData(_ data: DiscordVoiceData) {
		voiceQueue.async {
			self.onVoiceData(data)
		}
	}

	open func handleVoiceServerUpdate(with data: [String: Any]) {
		DefaultDiscordLogger.Logger.log("Handling voice server update", type: logType)
		DefaultDiscordLogger.Logger.verbose("Voice server update: %@", type: logType, args: data)

		self.voiceServerInformation = data

		if self.joiningVoiceChannel {
			// print("got voice server \(data)")
			self.startVoiceConnection()
		}
	}

	open func handleVoiceStateUpdate(with data: [String: Any]) {
		DefaultDiscordLogger.Logger.log("Handling voice state update", type: logType)
		DefaultDiscordLogger.Logger.verbose("Voice state: %@", type: logType, args: data)

		// Only care about our state right now
		guard data["user_id"] as? String == self.user?.id else { return }
		guard let guildId = data["guild_id"] as? String else { return }

		self.voiceState = DiscordVoiceState(voiceStateObject: data, guildId: guildId)

		if self.joiningVoiceChannel {
			// print("Got voice state \(data)")
			self.startVoiceConnection()
		}
	}

	public func guildForChannel(_ channelId: String) -> DiscordGuild? {
		return guilds.filter({ return $0.1.channels[channelId] != nil }).map({ $0.1 }).first
	}

	open func joinVoiceChannel(_ channelId: String) {
        #if !os(iOS)
		guard let guild = guildForChannel(channelId), let channel = guild.channels[channelId],
				channel.type == .voice else {

			return
		}

		DefaultDiscordLogger.Logger.log("Joining voice channel: %@", type: self.logType, args: channel)

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
        #else
        print("Only available on macOS and Linux")
        #endif
	}

	open func leaveVoiceChannel(_ channelId: String) {
        #if !os(iOS)
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
        #else
        print("Only available on macOS and Linux")
        #endif
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
        #if !os(iOS)
		// We need both to start the connection
		guard voiceState != nil && voiceServerInformation != nil else {
			return
		}

		// Reuse a previous engine's encoder if possible
		voiceEngine = DiscordVoiceEngine(client: self, voiceServerInformation: voiceServerInformation!,
			encoder: voiceEngine?.encoder, secret: voiceEngine?.secret)

		DefaultDiscordLogger.Logger.log("Connecting voice engine", type: logType)

		voiceEngine?.connect()
        #else
        print("Only available on macOS and Linux")
        #endif
	}
}
