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
open class DiscordClient : DiscordClientSpec, DiscordDispatchEventHandler,
		DiscordEndpointConsumer, DiscordShardManagerDelegate {
	// MARK: Properties

	/// The Discord JWT token.
	public let token: DiscordToken

	/// The client's delegate.
	public weak var delegate: DiscordClientDelegate?

	/// The manager for this client's shards.
	public var shardManager: DiscordShardManager!

	/// The queue that callbacks are called on. In addition, any reads from any properties of DiscordClient should be
	/// made on this queue, as this is the queue where modifications on them are made.
	public var handleQueue = DispatchQueue.main

    #if !os(iOS)
    /// The DiscordVoiceEngine that is used for voice.
	public var voiceEngine: DiscordVoiceEngineSpec?
    #endif

    /// A callback function to listen for voice packets.
	public var onVoiceData: (DiscordVoiceData) -> Void = {_ in }

	/// Whether large guilds should have their users fetched as soon as they are created.
	public var fillLargeGuilds = false

	/// Whether the client should query the API for users who aren't in the guild
	public var fillUsers = false

	/// Whether the client should remove users from guilds when they go offline.
	public var pruneUsers = false

	/// How many shards this client should spawn. Default is one.
	public var shards = 1

	/// Whether or not this client is connected.
	public private(set) var connected = false

	/// The direct message channels this user is in.
	public private(set) var directChannels = [String: DiscordChannel]()

	/// The guilds that this user is in.
	public private(set) var guilds = [String: DiscordGuild]()

	/// The relationships this user has. Only valid for non-bot users.
	public private(set) var relationships = [[String: Any]]()

	/// The DiscordUser this client is connected to.
	public private(set) var user: DiscordUser?

	/// The voice state for this user, if they are in a voice channel.
	public private(set) var voiceState: DiscordVoiceState?

	private let parseQueue = DispatchQueue(label: "parseQueue")
	private let logType = "DiscordClient"
	private let voiceQueue = DispatchQueue(label: "voiceQueue")

	private var channelCache = [String: DiscordChannel]()
	private var joiningVoiceChannel = false
	private var joinedVoiceChannel: DiscordGuildChannel?
	private var voiceServerInformation: [String: Any]?

	// MARK: Initializers

	/**
		- parameter token: The discord token of the user
		- parameter configuration: An array of DiscordClientOption that can be used to customize the client

	*/
	public required init(token: DiscordToken, configuration: [DiscordClientOption] = []) {
		self.token = token
		self.shardManager = DiscordShardManager(delegate: self)

		for config in configuration {
			switch config {
			case let .handleQueue(queue):
				handleQueue = queue
			case let .log(level):
				DefaultDiscordLogger.Logger.level = level
			case let .logger(logger):
				DefaultDiscordLogger.Logger = logger
			case let .shards(shards) where shards > 0:
				self.shards = shards
			case .fillLargeGuilds:
				fillLargeGuilds = true
			case .fillUsers:
				fillUsers = true
			case .pruneUsers:
				pruneUsers = true
			default:
				continue
			}
		}
	}

	// MARK: Methods

	/**
		Begins the connection to Discord. Once this is called, wait for a `connect` event before trying to interact
		with the client.
	*/
	open func connect() {
		DefaultDiscordLogger.Logger.log("Connecting", type: logType)

		shardManager.shatter(into: shards)
		shardManager.connect()
	}

	/**
		Disconnects from Discord. A `disconnect` event is fired when the client has successfully disconnected.

		Calling this method turns off automatic resuming, set `resume` to `true` before calling `connect()` again.
	*/
	open func disconnect() {
		DefaultDiscordLogger.Logger.log("Disconnecting", type: logType)

		connected = false

		shardManager.disconnect()

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
			DefaultDiscordLogger.Logger.debug("Couldn't find channel %@", type: logType, args: channelId)

			return nil
		}

		channelCache[channel.id] = channel

		DefaultDiscordLogger.Logger.debug("Found channel %@", type: logType, args: channel)

		return channel
	}

	// Handling

	/**
		Handles a dispatch event. This will call one of the other handle methods or the standard event handler.

		- parameter event: The dispatch event
		- parameter data: The dispatch event's data
	*/
	open func handleDispatch(event: DiscordDispatchEvent, data: DiscordGatewayPayloadData) {
		guard case let .object(eventData) = data else {
			DefaultDiscordLogger.Logger.error("Got dispatch event without an object: %@, %@",
				type: "DiscordDispatchEventHandler", args: event, data)

			return
		}

		switch event {
		case .presenceUpdate:		handlePresenceUpdate(with: eventData)
		case .messageCreate: 		handleMessageCreate(with: eventData)
		case .guildMemberAdd:		handleGuildMemberAdd(with: eventData)
		case .guildMembersChunk:	handleGuildMembersChunk(with: eventData)
		case .guildMemberUpdate:	handleGuildMemberUpdate(with: eventData)
		case .guildMemberRemove:	handleGuildMemberRemove(with: eventData)
		case .guildRoleCreate:		handleGuildRoleCreate(with: eventData)
		case .guildRoleDelete:		handleGuildRoleRemove(with: eventData)
		case .guildRoleUpdate:		handleGuildRoleUpdate(with: eventData)
		case .guildCreate:			handleGuildCreate(with: eventData)
		case .guildDelete:			handleGuildDelete(with: eventData)
		case .guildUpdate:			handleGuildUpdate(with: eventData)
		case .guildEmojisUpdate:	handleGuildEmojiUpdate(with: eventData)
		case .channelUpdate:		handleChannelUpdate(with: eventData)
		case .channelCreate:		handleChannelCreate(with: eventData)
		case .channelDelete:		handleChannelDelete(with: eventData)
		case .voiceServerUpdate:	handleVoiceServerUpdate(with: eventData)
		case .voiceStateUpdate:		handleVoiceStateUpdate(with: eventData)
		case .ready:				handleReady(with: eventData)
		default:					delegate?.client(self, didNotHandleDispatchEvent: event, withData: eventData)
		}
	}

	/**
		Handles engine dispatch events. You shouldn't need to call this method directly.

		Override to provide custom engine dispatch functionality.

		- parameter payload: A `DiscordGatewayPayload` containing the dispatch information.
	*/
	open func handleEngineDispatch(_ event: DiscordDispatchEvent, with payload: DiscordGatewayPayload) {
		handleQueue.async {
			self.handleDispatch(event: event, data: payload.payload)
		}
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
		self.joinedVoiceChannel = channel

		let shardNum = guild.shardNumber(assuming: shards)

		self.shardManager.sendPayload(DiscordGatewayPayload(code: .gateway(.voiceStatusUpdate),
			payload: .object([
				"guild_id": guild.id,
				"channel_id": channel.id,
				"self_mute": false,
				"self_deaf": false
				])
			), onShard: shardNum)
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

        guard let shardNum = joinedVoiceChannel?.guild?.shardNumber(assuming: shards) else { return }

        self.shardManager.sendPayload(DiscordGatewayPayload(code: .gateway(.voiceStatusUpdate),
        	payload: .object([
        		"guild_id": state.guildId,
        		"channel_id": NSNull(),
        		"self_mute": false,
        		"self_deaf": false
			])), onShard: shardNum)

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

		guard let shardNum = guilds[guildId]?.shardNumber(assuming: shards) else { return }

		shardManager.sendPayload(DiscordGatewayPayload(code: .gateway(.requestGuildMembers),
			payload: .object(requestObject)), onShard: shardNum)
	}

	/**
		Sets the user's presence.

		- parameter presence: The new presence object
	*/
	open func setPresence(_ presence: DiscordPresenceUpdate) {
		shardManager.sendPayload(DiscordGatewayPayload(code: .gateway(.statusUpdate),
			payload: .object(presence.json)), onShard: 0)
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

	open func voiceEngineReady(engine: DiscordVoiceEngine) {
		delegate?.client(self, isReadyToSendVoiceWithEngine: engine)
	}

	// MARK: DiscordDispatchEventHandler Conformance

	/**
		Handles channel creates from Discord. You shouldn't need to call this method directly.

		Override to provide additional custmization around this event.

		Emits the `channelCreate` event with a single data item of type `DiscordChannel`, which is the created channel.

		- parameter with: The data from the event
	*/
	open func handleChannelCreate(with data: [String: Any]) {
		DefaultDiscordLogger.Logger.log("Handling channel create", type: logType)

		guard let channel = channelFromObject(data, withClient: self) else { return }

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

		delegate?.client(self, didCreateChannel: channel)
	}

	/**
		Handles channel deletes from Discord. You shouldn't need to call this method directly.

		Override to provide additional custmization around this event.

		Emits the `channelDelete` event with a single data item of type `DiscordChannel`, which is the deleted channel.

		- parameter with: The data from the event
	*/
	open func handleChannelDelete(with data: [String: Any]) {
		DefaultDiscordLogger.Logger.log("Handling channel delete", type: logType)

		guard let guildId = data["guild_id"] as? String else { return }
		guard let channelId = data["id"] as? String else { return }
		guard let removedChannel = guilds[guildId]?.channels.removeValue(forKey: channelId) else { return }

		channelCache.removeValue(forKey: removedChannel.id)

		DefaultDiscordLogger.Logger.verbose("Removed channel: %@", type: logType, args: removedChannel)

		delegate?.client(self, didDeleteChannel: removedChannel)
	}

	/**
		Handles channel updates from Discord. You shouldn't need to call this method directly.

		Override to provide additional custmization around this event.

		Emits the `channelUpdate` event with a single data item of type `DiscordChannel`, which is the updated channel.

		- parameter with: The data from the event
	*/
	open func handleChannelUpdate(with data: [String: Any]) {
		DefaultDiscordLogger.Logger.log("Handling channel update", type: logType)

		let channel = DiscordGuildChannel(guildChannelObject: data, client: self)

		DefaultDiscordLogger.Logger.verbose("Updated channel: %@", type: logType, args: channel)

		guilds[channel.guildId]?.channels[channel.id] = channel

		channelCache.removeValue(forKey: channel.id)

		delegate?.client(self, didUpdateChannel: channel)
	}

	/**
		Handles guild creates from Discord. You shouldn't need to call this method directly.

		Override to provide additional custmization around this event.

		Emits the `guildCreate` event with a single data item of type `DiscordGuild`, which is the created guild.

		- parameter with: The data from the event
	*/
	open func handleGuildCreate(with data: [String: Any]) {
		DefaultDiscordLogger.Logger.log("Handling guild create", type: logType)

		let guild = DiscordGuild(guildObject: data, client: self)

		DefaultDiscordLogger.Logger.verbose("Created guild: %@", type: self.logType, args: guild)

		guilds[guild.id] = guild

		delegate?.client(self, didCreateGuild: guild)

		guard fillLargeGuilds && guild.large else { return }

		// Fill this guild with users immediately
		DefaultDiscordLogger.Logger.debug("Fill large guild %@ with all users", type: logType, args: guild.id)

		requestAllUsers(on: guild.id)
	}

	/**
		Handles guild deletes from Discord. You shouldn't need to call this method directly.

		Override to provide additional custmization around this event.

		Emits the `guildDelete` event with a single data item of type `DiscordGuild`, which is the deleted guild.

		- parameter with: The data from the event
	*/
	open func handleGuildDelete(with data: [String: Any]) {
		DefaultDiscordLogger.Logger.log("Handling guild delete", type: logType)

		guard let guildId = data["id"] as? String else { return }
		guard let removedGuild = guilds.removeValue(forKey: guildId) else { return }

		DefaultDiscordLogger.Logger.verbose("Removed guild: %@", type: logType, args: removedGuild)

		delegate?.client(self, didDeleteGuild: removedGuild)
	}

	/**
		Handles guild emoji updates from Discord. You shouldn't need to call this method directly.

		Override to provide additional custmization around this event.

		Emits the `guildEmojisUpdate` event with two data items, the first is a dictionary of `DiscordEmoji` indexed by
		their ids, and the second is the id of the guild that the emoji belong to.

		- parameter with: The data from the event
	*/
	open func handleGuildEmojiUpdate(with data: [String: Any]) {
		DefaultDiscordLogger.Logger.log("Handling guild emoji update", type: logType)

		guard let guildId = data["guild_id"] as? String, let guild = guilds[guildId] else { return }
		guard let emojis = data["emojis"] as? [[String: Any]] else { return }

		let discordEmojis = DiscordEmoji.emojisFromArray(emojis)

		DefaultDiscordLogger.Logger.verbose("Created guild emojis: %@", type: logType, args: discordEmojis)

		guild.emojis = discordEmojis

		delegate?.client(self, didUpdateEmojis: discordEmojis, onGuild: guild)
	}

	/**
		Handles guild member adds from Discord. You shouldn't need to call this method directly.

		Override to provide additional custmization around this event.

		Emits the `guildMemberAdd` event with two data items, the first is the `DiscordGuildMember` of the added member,
		the second is the id of the guild this member was added to.

		- parameter with: The data from the event
	*/
	open func handleGuildMemberAdd(with data: [String: Any]) {
		DefaultDiscordLogger.Logger.log("Handling guild member add", type: logType)

		let guildMember = DiscordGuildMember(guildMemberObject: data)
		guard let guildId = guildMember.guildId else { return }

		DefaultDiscordLogger.Logger.verbose("Created guild member: %@", type: logType, args: guildMember)

		guilds[guildId]?.members[guildMember.user.id] = guildMember
		guilds[guildId]?.memberCount += 1

		delegate?.client(self, didAddGuildMember: guildMember)
	}

	/**
		Handles guild member removes from Discord. You shouldn't need to call this method directly.

		Override to provide additional custmization around this event.

		Emits the `guildMemberRemove` event with two data items, the first is the `DiscordGuildMember` of the removed
		member, the second is the id of the guild this member was removed from.

		- parameter with: The data from the event
	*/
	open func handleGuildMemberRemove(with data: [String: Any]) {
		DefaultDiscordLogger.Logger.log("Handling guild member remove", type: logType)

		guard let guildId = data["guild_id"] as? String else { return }
		guard let user = data["user"] as? [String: Any], let id = user["id"] as? String else { return }

		guilds[guildId]?.memberCount -= 1

		guard let removedGuildMember = guilds[guildId]?.members.removeValue(forKey: id) else { return }

		DefaultDiscordLogger.Logger.verbose("Removed guild member: %@", type: logType, args: removedGuildMember)

		delegate?.client(self, didRemoveGuildMember: removedGuildMember)
	}

	/**
		Handles guild member updates from Discord. You shouldn't need to call this method directly.

		Override to provide additional custmization around this event.

		Emits the `guildMemberUpdate` event with two data items, the first is the id of the updated member,
		the second is the id of the guild this member was updated on.

		- parameter with: The data from the event
	*/
	open func handleGuildMemberUpdate(with data: [String: Any]) {
		DefaultDiscordLogger.Logger.log("Handling guild member update", type: logType)

		guard let guildId = data["guild_id"] as? String else { return }
		guard let user = data["user"] as? [String: Any], let id = user["id"] as? String else { return }

		guilds[guildId]?.members[id]?.updateMember(data)

		DefaultDiscordLogger.Logger.verbose("Updated guild member: %@", type: logType, args: id)

		guard let guildMember = guilds[guildId]?.members[id] else { return }

		delegate?.client(self, didUpdateGuildMember: guildMember)
	}

	/**
		Handles guild members chunks from Discord. You shouldn't need to call this method directly.

		Override to provide additional custmization around this event.

		Emits the `guildMembersChunk` event with two data items, the first is a dictionary of `DiscordGuildMember`
		indexed by their id, the second is the id of the guild for this chunk.

		- parameter with: The data from the event
	*/
	open func handleGuildMembersChunk(with data: [String: Any]) {
		DefaultDiscordLogger.Logger.log("Handling guild members chunk", type: logType)

		guard let guildId = data["guild_id"] as? String else { return }
		guard let members = data["members"] as? [[String: Any]] else { return }

		parseQueue.async {
			let guildMembers = DiscordGuildMember.guildMembersFromArray(members)

			self.handleQueue.async {
				guard let guild = self.guilds[guildId] else { return }

				for (memberId, member) in guildMembers {
					guild.members[memberId] = member
				}

				self.delegate?.client(self, didHandleGuildMemberChunk: guildMembers, forGuild: guild)
			}
		}
	}

	/**
		Handles guild role creates from Discord. You shouldn't need to call this method directly.

		Override to provide additional custmization around this event.

		Emits the `guildRoleCreate` event with one data item, the `DiscordRole` that was created

		- parameter with: The data from the event
	*/
	open func handleGuildRoleCreate(with data: [String: Any]) {
		DefaultDiscordLogger.Logger.log("Handling guild role create", type: logType)

		guard let guildId = data["guild_id"] as? String else { return }
		guard let roleObject = data["role"] as? [String: Any] else { return }

		let role = DiscordRole(roleObject: roleObject)

		DefaultDiscordLogger.Logger.verbose("Created role: %@", type: logType, args: role)

		guilds[guildId]?.roles[role.id] = role

		delegate?.client(self, didCreateRole: role)
	}

	/**
		Handles guild role removes from Discord. You shouldn't need to call this method directly.

		Override to provide additional custmization around this event.

		Emits the `guildRoleRemove` event with one data item, the `DiscordRole` that was removed.

		- parameter with: The data from the event
	*/
	open func handleGuildRoleRemove(with data: [String: Any]) {
		DefaultDiscordLogger.Logger.log("Handling guild role remove", type: logType)

		guard let guildId = data["guild_id"] as? String else { return }
		guard let roleId = data["role_id"] as? String else { return }
		guard let removedRole = guilds[guildId]?.roles.removeValue(forKey: roleId) else { return }

		DefaultDiscordLogger.Logger.verbose("Removed role: %@", type: logType, args: removedRole)

		delegate?.client(self, didDeleteRole: removedRole)
	}

	/**
		Handles guild member updates from Discord. You shouldn't need to call this method directly.

		Override to provide additional custmization around this event.

		Emits the `guildRoleUpdate` event with one data item, the role `DiscordRole` that was updated

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

		delegate?.client(self, didUpdateRole: role)
	}

	/**
		Handles guild updates from Discord. You shouldn't need to call this method directly.

		Override to provide additional custmization around this event.

		Emits the `guildUpdate` event with one data item, the `DiscordGuild` that was updated.

		- parameter with: The data from the event
	*/
	open func handleGuildUpdate(with data: [String: Any]) {
		DefaultDiscordLogger.Logger.log("Handling guild update", type: logType)

		guard let guildId = data["id"] as? String else { return }
		guard let updatedGuild = self.guilds[guildId]?.updateGuild(with: data) else { return }

		DefaultDiscordLogger.Logger.verbose("Updated guild: %@", type: logType, args: updatedGuild)

		delegate?.client(self, didUpdateGuild: updatedGuild)
	}

	/**
		Handles message creates from Discord. You shouldn't need to call this method directly.

		Override to provide additional custmization around this event.

		Emits the `messageCreate` event with one data item, the `DiscordMessage` that was created.

		- parameter with: The data from the event
	*/
	open func handleMessageCreate(with data: [String: Any]) {
		DefaultDiscordLogger.Logger.log("Handling message create", type: logType)

		let message = DiscordMessage(messageObject: data, client: self)

		DefaultDiscordLogger.Logger.verbose("Message: %@", type: logType, args: message)

		delegate?.client(self, didReceiveMessage: message)
	}

	/**
		Handles presence updates from Discord. You shouldn't need to call this method directly.

		Override to provide additional custmization around this event.

		Emits the `presenceUpdate` event with one data item, the `DiscordPresence` that was updated.

		- parameter with: The data from the event
	*/
	open func handlePresenceUpdate(with data: [String: Any]) {
		func handlePresence(_ presence: DiscordPresence, guild: DiscordGuild) {
			let userId = presence.user.id

			if pruneUsers && presence.status == .offline {
				DefaultDiscordLogger.Logger.debug("Pruning guild member %@ on %@", type: logType,
					args: userId, guild.id)

				guild.members[userId] = nil
				guild.presences[userId] = nil
			} else if fillUsers && !guild.members.contains(userId) {
				DefaultDiscordLogger.Logger.debug("Should get member %@; pull from the API", type: logType,
					args: userId)

				guild.members[lazy: userId] = .lazy({[weak guild] in
					guard let guild = guild else { return DiscordGuildMember(guildMemberObject: [:]) }

					return guild.getGuildMember(userId) ?? DiscordGuildMember(guildMemberObject: [:])
				})
			}
		}

		guard let guildId = data["guild_id"] as? String, let guild = guilds[guildId] else { return }
		guard let user = data["user"] as? [String: Any] else { return }
		guard let userId = user["id"] as? String else { return }

		var presence = guilds[guildId]?.presences[userId]

		if presence != nil {
			presence!.updatePresence(presenceObject: data)
		} else {
			presence = DiscordPresence(presenceObject: data, guildId: guildId)
		}

		DefaultDiscordLogger.Logger.debug("Updated presence: %@", type: logType, args: presence!)

		guild.presences[userId] = presence!

		delegate?.client(self, didReceivePresenceUpdate: presence!)

		guard pruneUsers || fillUsers else { return }

		handlePresence(presence!, guild: guild)
	}

	/**
		Handles the ready event from Discord. You shouldn't need to call this method directly.

		Override to provide additional custmization around this event.

		Emits the `ready` event with one data item, the raw `[String: Any]` for the event.

		- parameter with: The data from the event
	*/
	open func handleReady(with data: [String: Any]) {
		DefaultDiscordLogger.Logger.log("Handling ready", type: logType)

		if let user = data["user"] as? [String: Any] {
			self.user = DiscordUser(userObject: user)
		}

		if let guilds = data["guilds"] as? [[String: Any]] {
			for (id, guild) in DiscordGuild.guildsFromArray(guilds, client: self) {
				self.guilds.updateValue(guild, forKey: id)
			}
		}

		if let relationships = data["relationships"] as? [[String: Any]] {
			self.relationships += relationships
		}

		if let privateChannels = data["private_channels"] as? [[String: Any]] {
			for (id, channel) in privateChannelsFromArray(privateChannels, client: self) {
				self.directChannels.updateValue(channel, forKey: id)
			}
		}

		delegate?.client(self, didReceiveReady: data)
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

		Emits the `voiceStateUpdate` event with one data item, the `DiscordVoiceState`.

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

		delegate?.client(self, didReceiveVoiceStateUpdate: state)
	}

	// MARK: DiscordShardManagerDelegate conformance.

	/**
	    Signals that the manager has finished connecting.

	    - parameter manager: The manager.
	    - parameter didConnect: Should always be true.
	*/
	public func shardManager(_ manager: DiscordShardManager, didConnect connected: Bool) {
		handleQueue.async {
			self.connected = true

			self.delegate?.client(self, didConnect: true)
		}
	}

	/**
	    Signals that the manager has disconnected.

	    - parameter manager: The manager.
	    - parameter didDisconnectWithReason: The reason the manager disconnected.
	*/
	public func shardManager(_ manager: DiscordShardManager, didDisconnectWithReason reason: String) {
		handleQueue.async {
			self.connected = false

			self.delegate?.client(self, didDisconnectWithReason: "All shards closed")
		}
	}
}
