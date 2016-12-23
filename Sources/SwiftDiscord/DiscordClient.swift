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

/**
	The base class for SwiftDiscord. Most interaction with Discord will be done through this class.

	See `DiscordEndpointConsumer` for methods dealing with sending to Discord.

	Creating a client:

	```swift
	let client = DiscordClient(token: "Bot mysupersecretbottoken", configuration: [.log(.info)])
	```
*/
open class DiscordClient : DiscordClientSpec, DiscordDispatchEventHandler, DiscordEndpointConsumer {
	// MARK: Properties

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

	/// Whether this client tries to resume a previously established session.
	public var resume = true

	/// Whether or not this client is connected.
	public private(set) var connected = false

	/// The direct message channels this user is in.
	public private(set) var directChannels = [String: DiscordChannel]()

	/// The guilds that this user is in.
	public private(set) var guilds = [String: DiscordGuild]()

	/// The relationships this user has. Only valid for non-bot users.
	public private(set) var relationships = [[String: Any]]()

	/// The current session id.
	public private(set) var sessionId: String?

	/// The DiscordUser this client is connected to.
	public private(set) var user: DiscordUser?

	/// The voice state for this user, if they are in a voice channel.
	public private(set) var voiceState: DiscordVoiceState?

	// crunchQueue should be used for tasks would block the handleQueue for too long
	// DO NOT TOUCH ANY PROPERTIES WHILE ON THIS QUEUE. REENTER THE HANDLEQUEUE
	private let crunchQueue = DispatchQueue(label: "crunchQueue")
	private let logType = "DiscordClient"
	private let voiceQueue = DispatchQueue(label: "voiceQueue")

	private var channelCache = [String: DiscordChannel]()
	private var handlers = [String: DiscordEventHandler]()
	private var joiningVoiceChannel = false
	private var resuming = false
	private var voiceServerInformation: [String: Any]?

	// MARK: Initializers

	/**
		- parameter token: The discord token of the user
		- parameter configuration: An array of DiscordClientOption that can be used to customize the client

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
			case let .resume(resume):
				self.resume = resume
			}
		}
	}

	// MARK: Methods

	/**
		Attaches a `DiscordEngine`.

		You most likely won't need to call this method directly.

		Override this method to attach a custom engine that conforms to `DiscordEngineSpec`.
	*/
	open func attachEngine() {
		DefaultDiscordLogger.Logger.log("Attaching engine", type: logType)

		engine = DiscordEngine(client: self)

		on("engine.disconnect") {[weak self] data in
			guard let this = self else { return }

			this.connected = false

			this.handleQueue.async {
				this.handleEngineDisconnect(data)
			}
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

		Calling this method turns off automatic resuming, set `resume` to `true` before calling `connect()` again.
	*/
	open func disconnect() {
		DefaultDiscordLogger.Logger.log("Disconnecting", type: logType)

		connected = false
		resume = false
		resuming = false

		engine?.disconnect()

        #if !os(iOS)
		voiceEngine?.disconnect()
        #endif
	}

	/**
		Finds a channel by its snowflake.

		- parameter fromId: A channel snowflake

		- returns: An optional containing a `DiscordChannel` if one was found.
	*/
	public func findChannel(fromId channelId: String) -> DiscordChannel? {
		if let channel = channelCache[channelId] {
			DefaultDiscordLogger.Logger.debug("Got cached channel %@", type: logType, args: channel)

			return channel
		}

		let channel: DiscordChannel

		if let guild = guildForChannel(channelId), let guildChannel = guild.channels[channelId] {
			channel = guildChannel
		} else if let dmChannel = directChannels[channelId] {
			channel = dmChannel
		} else {
			return nil
		}

		channelCache[channel.id] = channel

		DefaultDiscordLogger.Logger.debug("Found channel %@", type: logType, args: channel)

		return channel
	}

	// Handling

	/**
		Adds event handlers to the client.

		- parameter event: The event to listen for
		- parameter callback: The callback that will be executed when this event is fired
	*/
	open func on(_ event: String, callback: @escaping ([Any]) -> Void) {
		handlers[event] = DiscordEventHandler(event: event, callback: callback)
	}

	/**
		The main event handle method. Calls the associated event handler.
		You shouldn't need to call this event directly.

		Override to provide custom event handling functionality.

		- parameter event: The event being fired
		- parameter with: The data from the event
	*/
	open func handleEvent(_ event: String, with data: [Any]) {
		handleQueue.async {
			self.handlers[event]?.executeCallback(with: data)
		}
	}

	/**
		Called after the client receives a disconnect event from the engine. This method decides whether to initate a
		resume, or to emit a disconnect event.

		- parameter disconnectData: The data from the disconnect event
	*/
	open func handleEngineDisconnect(_ disconnectData: [Any]) {
		guard resume else {
			handleEvent("disconnect", with: disconnectData)

			return
		}

		resumeGateway()
	}

	/**
		Handles engine dispatch events. You shouldn't need to call this method directly.

		Override to provide custom engine dispatch functionality.

		- parameter payload: A `DiscordGatewayPayload` containing the dispatch information.
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

		Override to provide additional custmization around this event.

		- parameter event: The engine event
		- parameter with: The data from the event
	*/
	open func handleEngineEvent(_ event: String, with data: [Any]) {
		handleEvent(event, with: data)
	}

	/**
		Handles voice data received from the VoiceEngine

		- paramter data: A DiscordVoiceData tuple
	*/
	open func handleVoiceData(_ data: DiscordVoiceData) {
		voiceQueue.async {
			self.onVoiceData(data)
		}
	}

	/**
	    Invalides the current session id.
	*/
	open func invalidateSession() {
		DefaultDiscordLogger.Logger.log("Invalidating the current session", type: logType)

		// The engine is telling us this session isn't valid anymore, clear it and stop resuming.
		handleQueue.sync {
			self.sessionId = nil
			self.resuming = false
		}
	}

	/**
		Gets the `DiscordGuild` for a channel snowflake.

		- parameter channelId: A channel snowflake

		- returns: An optional containing a `DiscordGuild` if one was found.
	*/
	public func guildForChannel(_ channelId: String) -> DiscordGuild? {
		return guilds.filter({ return $0.1.channels[channelId] != nil }).map({ $0.1 }).first
	}

	/**
		Joins a voice channel. A `voiceEngine.ready` event will be fired when the client has joined the channel.

		- parameter channelId: The snowflake of the voice channel you would like to join
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

		- parameter on: The snowflake of the guild you wish to request all users.
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
		Tries to resume a disconnected gateway connection.
	*/
	open func resumeGateway() {
		guard sessionId != nil, resume else { return }
		guard !resuming else {
			DefaultDiscordLogger.Logger.debug("Already trying to resume, ignoring", type: logType)

			return
		}

		DefaultDiscordLogger.Logger.log("Trying to resume gateway session", type: logType)

		resuming = true

		handleEvent("resumeStart", with: [])

		_resumeGateway(wait: 0)
	}

	private func _resumeGateway(wait: Int) {
		handleQueue.asyncAfter(deadline: DispatchTime.now() + Double(wait)) {[weak self] in
			guard let this = self, !this.connected, this.resuming else { return }

			DefaultDiscordLogger.Logger.debug("Calling engine connect for gateway resume with wait: %@",
				type: this.logType, args: wait)

			this.engine?.connect()

			this._resumeGateway(wait: wait + 10)
		}
	}

	/**
		Sets the user's presence.

		- parameter presence: The new presence object
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

	// MARK: DiscordDispatchEventHandler Conformance

	/**
		Handles channel creates from Discord. You shouldn't need to call this method directly.

		Override to provide additional custmization around this event.

		- parameter with: The data from the event
	*/
	open func handleChannelCreate(with data: [String: Any]) {
		DefaultDiscordLogger.Logger.log("Handling channel create", type: logType)

		guard var channel = channelFromObject(data) else { return }

		channel.client = self

		switch channel {
		case let guildChannel as DiscordGuildChannel:
			guilds[guildChannel.guildId]?.channels[guildChannel.id] = guildChannel
		case is DiscordDMChannel:
			fallthrough
		case is DiscordGroupDMChannel:
			directChannels[channel.id] = channel
		default:
			break
		}

		DefaultDiscordLogger.Logger.verbose("Created channel: %@", type: logType, args: channel)

		handleEvent("channelCreate", with: [channel])
	}

	/**
		Handles channel deletes from Discord. You shouldn't need to call this method directly.

		Override to provide additional custmization around this event.

		- parameter with: The data from the event
	*/
	open func handleChannelDelete(with data: [String: Any]) {
		DefaultDiscordLogger.Logger.log("Handling channel delete", type: logType)

		guard let guildId = data["guild_id"] as? String else { return }
		guard let channelId = data["id"] as? String else { return }
		guard let removedChannel = guilds[guildId]?.channels.removeValue(forKey: channelId) else { return }

		channelCache.removeValue(forKey: removedChannel.id)

		DefaultDiscordLogger.Logger.verbose("Removed channel: %@", type: logType, args: removedChannel)

		handleEvent("channelDelete", with: [guildId, removedChannel])
	}

	/**
		Handles channel updates from Discord. You shouldn't need to call this method directly.

		Override to provide additional custmization around this event.

		- parameter with: The data from the event
	*/
	open func handleChannelUpdate(with data: [String: Any]) {
		DefaultDiscordLogger.Logger.log("Handling channel update", type: logType)

		let channel = DiscordGuildChannel(guildChannelObject: data, client: self)

		DefaultDiscordLogger.Logger.verbose("Updated channel: %@", type: logType, args: channel)

		guilds[channel.guildId]?.channels[channel.id] = channel

		channelCache.removeValue(forKey: channel.id)

		handleEvent("channelUpdate", with: [channel.guildId, channel])
	}

	/**
		Handles guild creates from Discord. You shouldn't need to call this method directly.

		Override to provide additional custmization around this event.

		- parameter with: The data from the event
	*/
	open func handleGuildCreate(with data: [String: Any]) {
		DefaultDiscordLogger.Logger.log("Handling guild create", type: logType)

		let guild = DiscordGuild(guildObject: data, client: self)

		DefaultDiscordLogger.Logger.verbose("Created guild: %@", type: self.logType, args: guild)

		guilds[guild.id] = guild

		handleEvent("guildCreate", with: [guild.id, guild])
	}

	/**
		Handles guild deletes from Discord. You shouldn't need to call this method directly.

		Override to provide additional custmization around this event.

		- parameter with: The data from the event
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

		Override to provide additional custmization around this event.

		- parameter with: The data from the event
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

		Override to provide additional custmization around this event.

		- parameter with: The data from the event
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

		Override to provide additional custmization around this event.

		- parameter with: The data from the event
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

		Override to provide additional custmization around this event.

		- parameter with: The data from the event
	*/
	open func handleGuildMemberUpdate(with data: [String: Any]) {
		DefaultDiscordLogger.Logger.log("Handling guild member update", type: logType)

		guard let guildId = data["guild_id"] as? String else { return }
		guard let user = data["user"] as? [String: Any], let id = user["id"] as? String else { return }

		guilds[guildId]?.members[id]?.updateMember(data)

		DefaultDiscordLogger.Logger.verbose("Updated guild member: %@", type: logType, args: id)

		handleEvent("guildMemberUpdate", with: [guildId, id])
	}

	/**
		Handles guild members chunks from Discord. You shouldn't need to call this method directly.

		Override to provide additional custmization around this event.

		- parameter with: The data from the event
	*/
	open func handleGuildMembersChunk(with data: [String: Any]) {
		DefaultDiscordLogger.Logger.log("Handling guild members chunk", type: logType)

		guard let guildId = data["guild_id"] as? String else { return }
		guard let members = data["members"] as? [[String: Any]] else { return }

		crunchQueue.async {
			let guildMembers = DiscordGuildMember.guildMembersFromArray(members)

			self.handleQueue.async {
				guard let guild = self.guilds[guildId] else { return }

				for (memberId, member) in guildMembers {
					guild.members[memberId] = member
				}

				self.handleEvent("guildMembersChunk", with: [guildId, guildMembers])
			}
		}
	}

	/**
		Handles guild role creates from Discord. You shouldn't need to call this method directly.

		Override to provide additional custmization around this event.

		- parameter with: The data from the event
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

		Override to provide additional custmization around this event.

		- parameter with: The data from the event
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

		Override to provide additional custmization around this event.

		- parameter with: The data from the event
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

		Override to provide additional custmization around this event.

		- parameter with: The data from the event
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

		Override to provide additional custmization around this event.

		- parameter with: The data from the event
	*/
	open func handleMessageCreate(with data: [String: Any]) {
		DefaultDiscordLogger.Logger.log("Handling message create", type: logType)

		let message = DiscordMessage(messageObject: data, client: self)

		DefaultDiscordLogger.Logger.verbose("Message: %@", type: logType, args: message)

		handleEvent("messageCreate", with: [message])
	}

	/**
		Handles presence updates from Discord. You shouldn't need to call this method directly.

		Override to provide additional custmization around this event.

		- parameter with: The data from the event
	*/
	open func handlePresenceUpdate(with data: [String: Any]) {
		// DefaultDiscordLogger.Logger.debug("Handling presence update", type: logType)

		guard let guildId = data["guild_id"] as? String else { return }
		guard let user = data["user"] as? [String: Any] else { return }
		guard let userId = user["id"] as? String else { return }

		var presence = guilds[guildId]?.presences[userId]

		if presence != nil {
			presence!.updatePresence(presenceObject: data)
		} else {
			presence = DiscordPresence(presenceObject: data, guildId: guildId)
		}

		// DefaultDiscordLogger.Logger.debug("Updated presence: %@", type: logType, args: presence!)

		guilds[guildId]?.presences[userId] = presence!

		handleEvent("presenceUpdate", with: [guildId, presence!])
	}

	/**
		Handles the ready event from Discord. You shouldn't need to call this method directly.

		Override to provide additional custmization around this event.

		- parameter with: The data from the event
	*/
	open func handleReady(with data: [String: Any]) {
		DefaultDiscordLogger.Logger.log("Handling ready", type: logType)

		if let user = data["user"] as? [String: Any] {
			self.user = DiscordUser(userObject: user)
		}

		if let guilds = data["guilds"] as? [[String: Any]] {
			self.guilds = DiscordGuild.guildsFromArray(guilds, client: self)
		}

		if let relationships = data["relationships"] as? [[String: Any]] {
			self.relationships = relationships
		}

		if let privateChannels = data["private_channels"] as? [[String: Any]] {
			self.directChannels = privateChannelsFromArray(privateChannels)
		}

		if let sessionId = data["session_id"] as? String {
			DefaultDiscordLogger.Logger.log("Got sessionId: %@", type: logType, args: sessionId)

			self.sessionId = sessionId
		}

		connected = true
		resuming = false
		handleEvent("connect", with: [data])
	}


	/**
		Handles the resumed event from Discord. You shouldn't need to call this method directly.

		Override to provide additional custmization around this event.

		- parameter with: The data from the event
	*/
	open func handleResumed(with data: [String: Any]) {
		DefaultDiscordLogger.Logger.log("Resumed gateway session", type: logType)

		resuming = false
		connected = true

		// Start the engine's heartbeat again
		engine?.sendHeartbeat()

		handleEvent("resumed", with: [])
	}

	/**
		Handles voice server updates from Discord. You shouldn't need to call this method directly.

		Override to provide additional custmization around this event.

		- parameter with: The data from the event
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

		Override to provide additional custmization around this event.

		- parameter with: The data from the event
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
}
