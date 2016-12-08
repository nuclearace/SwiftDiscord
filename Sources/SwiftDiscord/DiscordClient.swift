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

///The base class for SwiftDiscord. Most interaction with Discord will be done through this class.
open class DiscordClient : DiscordClientSpec, DiscordDispatchEventHandler, DiscordEndpointConsumer {
	/// The Discord JWT token.
	public let token: DiscordToken

	/// The main WebSocket engine used to communicate with Discord.
	public var engine: DiscordEngineSpec?

	/// The queue that callbacks are called on. In addition, any reads from any properties of DiscordClient should be
	/// made on this queue, as this is the queue where modifications on them are made.
	public var handleQueue = DispatchQueue.main
    #if !os(iOS)
    /// The DiscordVoiceEngine that is used for voice.
	public var voiceEngine: DiscordVoiceEngineSpec?
    #endif

    /// A callback function to listen for voice packets.
	public var onVoiceData: (DiscordVoiceData) -> Void = {_ in }

	/// Whether or not this client is connected.
	public private(set) var connected = false

	/// The guilds that this user is in.
	public private(set) var guilds = [String: DiscordGuild]()

	/// The relationships this user has. Only valid for non-bot users.
	public private(set) var relationships = [[String: Any]]()

	/// The DiscordUser this client is connected to.
	public private(set) var user: DiscordUser?

	/// The voice state for this user, if they are in a voice channel.
	public private(set) var voiceState: DiscordVoiceState?

	// crunchQueue should be used for tasks would block the handleQueue for too long
	// DO NOT TOUCH ANY PROPERTIES WHILE ON THIS QUEUE. REENTER THE HANDLEQUEUE
	private let crunchQueue = DispatchQueue(label: "crunchQueue")
	private let logType = "DiscordClient"
	private let voiceQueue = DispatchQueue(label: "voiceQueue")

	private var handlers = [String: DiscordEventHandler]()
	private var joiningVoiceChannel = false
	private var voiceServerInformation: [String: Any]?

	/**
		- Parameters:
			- token: The discord token of the user
			- configuration: An array of DiscordClientOption that can be used to customize the client

	*/
	public required init(token: DiscordToken, configuration: [DiscordClientOption] = []) {
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

	/**
		Attaches the DiscordEngine.

		You most likely won't need to call this method directly.

		Override this method to attach a custom engine that conforms to DiscordEngineSpec
	*/
	open func attachEngine() {
		DefaultDiscordLogger.Logger.log("Attaching engine", type: logType)

		engine = DiscordEngine(client: self)

		on("engine.disconnect") {[weak self] data in
			self?.handleEvent("disconnect", with: data)
		}
	}

	/**
		Begins the connection to Discord. Once this is called, wait for a `connect` event before trying to interact
		with the client.
	*/
	open func connect() {
		DefaultDiscordLogger.Logger.log("Connecting", type: logType)

		attachEngine()

		engine?.connect()
	}


	/**
		Disconnects from Discord. A `disconnect` event is fired when the client has successfully disconnected.
	*/
	open func disconnect() {
		DefaultDiscordLogger.Logger.log("Disconnecting", type: logType)

		connected = false

		engine?.disconnect()

        #if !os(iOS)
		voiceEngine?.disconnect()
        #endif
	}

	// Handling

	/**
		Adds event handlers to the client.

		- Parameters:
			- _: The event to listen for
			- callback: The callback that will be executed when this event is fired
	*/
	open func on(_ event: String, callback: @escaping ([Any]) -> Void) {
		handlers[event] = DiscordEventHandler(event: event, callback: callback)
	}

	/**
		Handles channel creates from Discord. You shouldn't need to call this method directly.

		Override to provide addition custmization around this event.

		- Parameters:
			- with: The data from the event
	*/
	open func handleChannelCreate(with data: [String: Any]) {
		DefaultDiscordLogger.Logger.log("Handling channel create", type: logType)

		let channel = DiscordGuildChannel(guildChannelObject: data)

		DefaultDiscordLogger.Logger.verbose("Created channel: %@", type: logType, args: channel)

		guilds[channel.guildId]?.channels[channel.id] = channel

		handleEvent("channelCreate", with: [channel.guildId, channel])
	}

	/**
		Handles channel deletes from Discord. You shouldn't need to call this method directly.

		Override to provide addition custmization around this event.

		- Parameters:
			- with: The data from the event
	*/
	open func handleChannelDelete(with data: [String: Any]) {
		DefaultDiscordLogger.Logger.log("Handling channel delete", type: logType)

		guard let guildId = data["guild_id"] as? String else { return }
		guard let channelId = data["id"] as? String else { return }

		guard let removedChannel = guilds[guildId]?.channels.removeValue(forKey: channelId) else { return }

		DefaultDiscordLogger.Logger.verbose("Removed channel: %@", type: logType, args: removedChannel)

		handleEvent("channelDelete", with: [guildId, removedChannel])
	}

	/**
		Handles channel updates from Discord. You shouldn't need to call this method directly.

		Override to provide addition custmization around this event.

		- Parameters:
			- with: The data from the event
	*/
	open func handleChannelUpdate(with data: [String: Any]) {
		DefaultDiscordLogger.Logger.log("Handling channel update", type: logType)

		let channel = DiscordGuildChannel(guildChannelObject: data)

		DefaultDiscordLogger.Logger.verbose("Updated channel: %@", type: logType, args: channel)

		guilds[channel.guildId]?.channels[channel.id] = channel

		handleEvent("channelUpdate", with: [channel.guildId, channel])
	}

	/**
		The main event handle method. Calls the associated event handler.
		You shouldn't need to call this event directly.

		Override to provide custom event handling functionality.

		- Parameters:
			- _: The event being fired
			- with: The data from the event
	*/
	open func handleEvent(_ event: String, with data: [Any]) {
		handleQueue.async {
			self.handlers[event]?.executeCallback(with: data)
		}
	}

	/**
		Handles engine dispatch events. You shouldn't need to call this method directly.

		Override to provide custom engine dispatch functionality.

		- Parameters:
			- _: A DiscordGatewayPayload containing the dispatch information.
	*/
	open func handleEngineDispatch(_ payload: DiscordGatewayPayload) {
		guard let type = payload.name, let event = DiscordDispatchEvent(rawValue: type) else {
			DefaultDiscordLogger.Logger.error("Could not create dispatch event %@", type: logType, args: payload)

			return
		}

		handleQueue.async {
			self.handleDispatch(event: event, data: payload.payload)
		}
	}

	/**
		Handles an engine event. You shouldn't need to call this method directly.

		Override to provide addition custmization around this event.

		- Parameters:
			- _: The engine event
			- with: The data from the event
	*/
	open func handleEngineEvent(_ event: String, with data: [Any]) {
		handleEvent(event, with: data)
	}

	/**
		Handles guild creates from Discord. You shouldn't need to call this method directly.

		Override to provide addition custmization around this event.

		- Parameters:
			- with: The data from the event
	*/
	open func handleGuildCreate(with data: [String: Any]) {
		DefaultDiscordLogger.Logger.log("Handling guild create", type: logType)

		let guild = DiscordGuild(guildObject: data)

		DefaultDiscordLogger.Logger.verbose("Created guild: %@", type: self.logType, args: guild)

		guilds[guild.id] = guild

		handleEvent("guildCreate", with: [guild.id, guild])
	}

	/**
		Handles guild deletes from Discord. You shouldn't need to call this method directly.

		Override to provide addition custmization around this event.

		- Parameters:
			- with: The data from the event
	*/
	open func handleGuildDelete(with data: [String: Any]) {
		DefaultDiscordLogger.Logger.log("Handling guild delete", type: logType)

		guard let guildId = data["id"] as? String else { return }

		guard let removedGuild = guilds.removeValue(forKey: guildId) else { return }

		DefaultDiscordLogger.Logger.verbose("Removed guild: %@", type: logType, args: removedGuild)

		handleEvent("guildDelete", with: [guildId, removedGuild])
	}

	/**
		Handles guild emoji updates from Discord. You shouldn't need to call this method directly.

		Override to provide addition custmization around this event.

		- Parameters:
			- with: The data from the event
	*/
	open func handleGuildEmojiUpdate(with data: [String: Any]) {
		DefaultDiscordLogger.Logger.log("Handling guild emoji update", type: logType)

		guard let guildId = data["guild_id"] as? String else { return }
		guard let emojis = data["emojis"] as? [[String: Any]] else { return }

		let discordEmojis = DiscordEmoji.emojisFromArray(emojis)

		DefaultDiscordLogger.Logger.verbose("Created guild emojis: %@", type: logType, args: discordEmojis)

		guilds[guildId]?.emojis = discordEmojis

		handleEvent("guildEmojisUpdate", with: [guildId, discordEmojis])
	}

	/**
		Handles guild member adds from Discord. You shouldn't need to call this method directly.

		Override to provide addition custmization around this event.

		- Parameters:
			- with: The data from the event
	*/
	open func handleGuildMemberAdd(with data: [String: Any]) {
		DefaultDiscordLogger.Logger.log("Handling guild member add", type: logType)

		guard let guildId = data["guild_id"] as? String else { return }

		let guildMember = DiscordGuildMember(guildMemberObject: data)

		DefaultDiscordLogger.Logger.verbose("Created guild member: %@", type: logType, args: guildMember)

		guilds[guildId]?.members[guildMember.user.id] = guildMember
		guilds[guildId]?.memberCount += 1

		handleEvent("guildMemberAdd", with: [guildId, guildMember])
	}

	/**
		Handles guild member removes from Discord. You shouldn't need to call this method directly.

		Override to provide addition custmization around this event.

		- Parameters:
			- with: The data from the event
	*/
	open func handleGuildMemberRemove(with data: [String: Any]) {
		DefaultDiscordLogger.Logger.log("Handling guild member remove", type: logType)

		guard let guildId = data["guild_id"] as? String else { return }
		guard let user = data["user"] as? [String: Any], let id = user["id"] as? String else { return }

		guilds[guildId]?.memberCount -= 1

		if let removedGuildMember = guilds[guildId]?.members.removeValue(forKey: id) {
			DefaultDiscordLogger.Logger.verbose("Removed guild member: %@", type: logType, args: removedGuildMember)

			handleEvent("guildMemberRemove", with: [guildId, removedGuildMember])
		} else {
			handleEvent("guildMemberRemove", with: [guildId, data])
		}
	}

	/**
		Handles guild member updates from Discord. You shouldn't need to call this method directly.

		Override to provide addition custmization around this event.

		- Parameters:
			- with: The data from the event
	*/
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

	/**
		Handles guild members chunks from Discord. You shouldn't need to call this method directly.

		Override to provide addition custmization around this event.

		- Parameters:
			- with: The data from the event
	*/
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

	/**
		Handles guild role creates from Discord. You shouldn't need to call this method directly.

		Override to provide addition custmization around this event.

		- Parameters:
			- with: The data from the event
	*/
	open func handleGuildRoleCreate(with data: [String: Any]) {
		DefaultDiscordLogger.Logger.log("Handling guild role create", type: logType)

		guard let guildId = data["guild_id"] as? String else { return }
		guard let roleObject = data["role"] as? [String: Any] else { return }

		let role = DiscordRole(roleObject: roleObject)

		DefaultDiscordLogger.Logger.verbose("Created role: %@", type: logType, args: role)

		guilds[guildId]?.roles[role.id] = role

		handleEvent("guildRoleCreate", with: [guildId, role])
	}

	/**
		Handles guild role removes from Discord. You shouldn't need to call this method directly.

		Override to provide addition custmization around this event.

		- Parameters:
			- with: The data from the event
	*/
	open func handleGuildRoleRemove(with data: [String: Any]) {
		DefaultDiscordLogger.Logger.log("Handling guild role remove", type: logType)

		guard let guildId = data["guild_id"] as? String else { return }
		guard let roleId = data["role_id"] as? String else { return }

		guard let removedRole = guilds[guildId]?.roles.removeValue(forKey: roleId) else { return }

		DefaultDiscordLogger.Logger.verbose("Removed role: %@", type: logType, args: removedRole)

		handleEvent("guildRoleRemove", with: [guildId, removedRole])
	}

	/**
		Handles guild member updates from Discord. You shouldn't need to call this method directly.

		Override to provide addition custmization around this event.

		- Parameters:
			- with: The data from the event
	*/
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

	/**
		Handles guild updates from Discord. You shouldn't need to call this method directly.

		Override to provide addition custmization around this event.

		- Parameters:
			- with: The data from the event
	*/
	open func handleGuildUpdate(with data: [String: Any]) {
		DefaultDiscordLogger.Logger.log("Handling guild update", type: logType)

		guard let guildId = data["id"] as? String else { return }
		guard let updatedGuild = self.guilds[guildId]?.updateGuild(with: data) else { return }

		DefaultDiscordLogger.Logger.verbose("Updated guild: %@", type: logType, args: updatedGuild)

		handleEvent("guildUpdate", with: [guildId, updatedGuild])
	}

	/**
		Handles message creates from Discord. You shouldn't need to call this method directly.

		Override to provide addition custmization around this event.

		- Parameters:
			- with: The data from the event
	*/
	open func handleMessageCreate(with data: [String: Any]) {
		DefaultDiscordLogger.Logger.log("Handling message create", type: logType)

		let message = DiscordMessage(messageObject: data)

		DefaultDiscordLogger.Logger.verbose("Message: %@", type: logType, args: message)

		handleEvent("messageCreate", with: [message])
	}

	/**
		Handles presence updates from Discord. You shouldn't need to call this method directly.

		Override to provide addition custmization around this event.

		- Parameters:
			- with: The data from the event
	*/
	open func handlePresenceUpdate(with data: [String: Any]) {
		DefaultDiscordLogger.Logger.debug("Handling presence update", type: logType)

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

	/**
		Handles the ready event from Discord. You shouldn't need to call this method directly.

		Override to provide addition custmization around this event.

		- Parameters:
			- with: The data from the event
	*/
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

	/**
		Handles voice data received from the VoiceEngine
	*/
	open func handleVoiceData(_ data: DiscordVoiceData) {
		voiceQueue.async {
			self.onVoiceData(data)
		}
	}

	/**
		Handles voice server updates from Discord. You shouldn't need to call this method directly.

		Override to provide addition custmization around this event.

		- Parameters:
			- with: The data from the event
	*/
	open func handleVoiceServerUpdate(with data: [String: Any]) {
		DefaultDiscordLogger.Logger.log("Handling voice server update", type: logType)
		DefaultDiscordLogger.Logger.verbose("Voice server update: %@", type: logType, args: data)

		self.voiceServerInformation = data

		if self.joiningVoiceChannel {
			// print("got voice server \(data)")
			self.startVoiceConnection()
		}
	}

	/**
		Handles voice state updates from Discord. You shouldn't need to call this method directly.

		Override to provide addition custmization around this event.

		- Parameters:
			- with: The data from the event
	*/
	open func handleVoiceStateUpdate(with data: [String: Any]) {
		DefaultDiscordLogger.Logger.log("Handling voice state update", type: logType)

		guard let guildId = data["guild_id"] as? String else { return }

		let state = DiscordVoiceState(voiceStateObject: data, guildId: guildId)

		DefaultDiscordLogger.Logger.verbose("Voice state: %@", type: logType, args: state)

		if state.channelId == "" {
			guilds[guildId]?.voiceStates[state.userId] = nil
		} else {
			guilds[guildId]?.voiceStates[state.userId] = state
		}

		if state.userId == user?.id {
			if state.channelId == "" {
				voiceState = nil
			} else if joiningVoiceChannel {
				voiceState = state

				startVoiceConnection()
			}
		}

		handleEvent("voiceStateUpdate", with: [guildId, state])
	}

	/**
		Gets the DiscordGuild for a Channel snowflake.

		- Parameters:
			- _: A channel snowflake

		- Returns: An optional containing a DiscordGuild if one was found.
	*/
	public func guildForChannel(_ channelId: String) -> DiscordGuild? {
		return guilds.filter({ return $0.1.channels[channelId] != nil }).map({ $0.1 }).first
	}

	/**
		Joins a voice channel. A `voiceEngine.ready` event will be fired when the client has joined the channel.

		- Parameters:
			- _: The snowflake of the voice channel you would like to join

	*/
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

	/**
		Leaves the currently connected voice channel.
	*/
	open func leaveVoiceChannel() {
        #if !os(iOS)
        guard let state = voiceState else { return }

        self.voiceEngine?.disconnect()
        self.voiceEngine = nil

        self.engine?.sendGatewayPayload(DiscordGatewayPayload(code: .gateway(.voiceStatusUpdate),
        	payload: .object([
        		"guild_id": state.guildId,
        		"channel_id": NSNull(),
        		"self_mute": false,
        		"self_deaf": false
			]))
		)

		self.joiningVoiceChannel = false
        #else
        print("Only available on macOS and Linux")
        #endif
	}

	/**
		Requests all users from Discord for the guild specified. Use this when you need to get all users on a large
		guild. Multiple `guildMembersChunk` will be fired.

		- Parameters:
			- on: The snowflake of the guild you wish to request all users.
	*/
	open func requestAllUsers(on guildId: String) {
		let requestObject: [String: Any] = [
			"guild_id": guildId,
			"query": "",
			"limit": 0
		]

		engine?.sendGatewayPayload(DiscordGatewayPayload(code: .gateway(.requestGuildMembers),
			payload: .object(requestObject)))
	}

	/**
		Sets the user's presence.

		- Parameters:
			- _: The new presence object
	*/
	open func setPresence(_ presence: DiscordPresenceUpdate) {
		engine?.sendGatewayPayload(DiscordGatewayPayload(code: .gateway(.statusUpdate),
			payload: .object(presence.json)))
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
