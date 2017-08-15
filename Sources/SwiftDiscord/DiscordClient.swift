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

///
/// The base class for SwiftDiscord. Most interaction with Discord will be done through this class.
///
/// See `DiscordEndpointConsumer` for methods dealing with sending to Discord.
///
/// Creating a client:
///
/// ```swift
/// self.client = DiscordClient(token: "Bot mysupersecretbottoken", configuration: [.log(.info)])
/// ```
///
/// Once a client is created, you need to set its delegate so that you can start receiving events:
///
/// ```swift
/// self.client.delegate = self
/// ```
///
/// See `DiscordClientDelegate` for a list of delegate methods that can be implemented.
///
open class DiscordClient : DiscordClientSpec, DiscordDispatchEventHandler, DiscordEndpointConsumer {
    // MARK: Properties

    /// The rate limiter for this client.
    public let rateLimiter = DiscordRateLimiter()

    /// The Discord JWT token.
    public let token: DiscordToken

    /// The client's delegate.
    public weak var delegate: DiscordClientDelegate?

    /// If true, the client does not store presences.
    public var discardPresences = false

    /// The queue that callbacks are called on. In addition, any reads from any properties of DiscordClient should be
    /// made on this queue, as this is the queue where modifications on them are made.
    public var handleQueue = DispatchQueue.main

    /// The manager for this client's shards.
    public var shardManager: DiscordShardManager!

    /// If we should only represent a single shard, this is the shard information.
    public var singleShardInformation: DiscordShardInformation?

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
    public private(set) var directChannels = [ChannelID: DiscordTextChannel]()

    /// The guilds that this user is in.
    public private(set) var guilds = [GuildID: DiscordGuild]()

    /// The relationships this user has. Only valid for non-bot users.
    public private(set) var relationships = [[String: Any]]()

    /// The DiscordUser this client is connected to.
    public private(set) var user: DiscordUser?

    /// A manager for the voice engines.
    public private(set) var voiceManager: DiscordVoiceManager!

    var channelCache = [ChannelID: DiscordChannel]()

    private var logType: String { return "DiscordClient" }
    private let voiceQueue = DispatchQueue(label: "voiceQueue")

    // MARK: Initializers

    ///
    /// - parameter token: The discord token of the user
    /// - parameter delegate: The delegate for this client.
    /// - parameter configuration: An array of DiscordClientOption that can be used to customize the client
    ///
    public required init(token: DiscordToken, delegate: DiscordClientDelegate,
                         configuration: [DiscordClientOption] = []) {
        self.token = token
        self.shardManager = DiscordShardManager(delegate: self)
        self.voiceManager = DiscordVoiceManager(delegate: self)
        self.delegate = delegate

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
            case let .singleShard(shardInfo):
                self.singleShardInformation = shardInfo
            case .discardPresences:
                discardPresences = true
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

    ///
    /// Begins the connection to Discord. Once this is called, wait for a `connect` event before trying to interact
    /// with the client.
    ///
    open func connect() {
        DefaultDiscordLogger.Logger.log("Connecting", type: logType)

        if let shardInfo = singleShardInformation {
            shards = shardInfo.totalShards
            shardManager.manuallyShatter(withInfo: shardInfo)
        } else {
            shardManager.shatter(into: shards)
        }

        shardManager.connect()
    }

    ///
    /// Disconnects from Discord. A `disconnect` event is fired when the client has successfully disconnected.
    ///
    /// Calling this method turns off automatic resuming, set `resume` to `true` before calling `connect()` again.
    ///
    open func disconnect() {
        DefaultDiscordLogger.Logger.log("Disconnecting", type: logType)

        connected = false

        shardManager.disconnect()

        for (_, engine) in voiceManager.get(voiceManager.voiceEngines) {
            engine.disconnect()
        }
    }

    ///
    /// Finds a channel by its snowflake.
    ///
    /// - parameter fromId: A channel snowflake
    /// - returns: An optional containing a `DiscordChannel` if one was found.
    ///
    public func findChannel(fromId channelId: ChannelID) -> DiscordChannel? {
        if let channel = channelCache[channelId] {
            DefaultDiscordLogger.Logger.debug("Got cached channel \(channel)", type: logType)

            return channel
        }

        let channel: DiscordChannel

        if let guild = guildForChannel(channelId), let guildChannel = guild.channels[channelId] {
            channel = guildChannel
        } else if let dmChannel = directChannels[channelId] {
            channel = dmChannel
        } else {
            DefaultDiscordLogger.Logger.debug("Couldn't find channel \(channelId)", type: logType)

            return nil
        }

        channelCache[channel.id] = channel

        DefaultDiscordLogger.Logger.debug("Found channel \(channel)", type: logType)

        return channel
    }

    // Handling

    ///
    /// Handles a dispatch event. This will call one of the other handle methods or the standard event handler.
    ///
    /// - parameter event: The dispatch event
    /// - parameter data: The dispatch event's data
    ///
    open func handleDispatch(event: DiscordDispatchEvent, data: DiscordGatewayPayloadData) {
        guard case let .object(eventData) = data else {
            DefaultDiscordLogger.Logger.error("Got dispatch event without an object: \(event), \(data)",
                                              type: "DiscordDispatchEventHandler")
            return
        }

        switch event {
        case .presenceUpdate:        handlePresenceUpdate(with: eventData)
        case .messageCreate:         handleMessageCreate(with: eventData)
        case .messageUpdate:         handleMessageUpdate(with: eventData)
        case .guildMemberAdd:        handleGuildMemberAdd(with: eventData)
        case .guildMembersChunk:     handleGuildMembersChunk(with: eventData)
        case .guildMemberUpdate:     handleGuildMemberUpdate(with: eventData)
        case .guildMemberRemove:     handleGuildMemberRemove(with: eventData)
        case .guildRoleCreate:       handleGuildRoleCreate(with: eventData)
        case .guildRoleDelete:       handleGuildRoleRemove(with: eventData)
        case .guildRoleUpdate:       handleGuildRoleUpdate(with: eventData)
        case .guildCreate:           handleGuildCreate(with: eventData)
        case .guildDelete:           handleGuildDelete(with: eventData)
        case .guildUpdate:           handleGuildUpdate(with: eventData)
        case .guildEmojisUpdate:     handleGuildEmojiUpdate(with: eventData)
        case .channelUpdate:         handleChannelUpdate(with: eventData)
        case .channelCreate:         handleChannelCreate(with: eventData)
        case .channelDelete:         handleChannelDelete(with: eventData)
        case .voiceServerUpdate:     handleVoiceServerUpdate(with: eventData)
        case .voiceStateUpdate:      handleVoiceStateUpdate(with: eventData)
        case .ready:                 handleReady(with: eventData)
        default:                     delegate?.client(self, didNotHandleDispatchEvent: event, withData: eventData)
        }
    }

    ///
    /// Gets the `DiscordGuild` for a channel snowflake.
    ///
    /// - parameter channelId: A channel snowflake
    /// - returns: An optional containing a `DiscordGuild` if one was found.
    ///
    public func guildForChannel(_ channelId: ChannelID) -> DiscordGuild? {
        return guilds.filter({ $0.1.channels[channelId] != nil }).map({ $0.1 }).first
    }

    ///
    /// Joins a voice channel. A `voiceEngine.ready` event will be fired when the client has joined the channel.
    ///
    /// - parameter channelId: The snowflake of the voice channel you would like to join
    ///
    open func joinVoiceChannel(_ channelId: ChannelID) {
        guard let guild = guildForChannel(channelId), let channel = guild.channels[channelId] as? DiscordGuildVoiceChannel else {

            return
        }

        DefaultDiscordLogger.Logger.log("Joining voice channel: \(channel)", type: self.logType)

        shardManager.sendPayload(DiscordGatewayPayload(code: .gateway(.voiceStatusUpdate),
                                                       payload: .object(["guild_id": String(describing: guild.id),
                                                                         "channel_id": String(describing: channel.id),
                                                                         "self_mute": false,
                                                                         "self_deaf": false
                                                                        ])
        ), onShard: guild.shardNumber(assuming: shards))
    }

    ///
    /// Leaves the voice channel that is associated with the guild specified.
    ///
    /// - parameter onGuild: The snowflake of the guild that you want to leave.
    ///
    open func leaveVoiceChannel(onGuild guildId: GuildID) {
        DefaultDiscordLogger.Logger.log("Leaving voice channel on guild: \(guildId)", type: logType)

        voiceManager.leaveVoiceChannel(onGuild: guildId)
    }

    ///
    /// Requests all users from Discord for the guild specified. Use this when you need to get all users on a large
    /// guild. Multiple `guildMembersChunk` will be fired.
    ///
    /// - parameter on: The snowflake of the guild you wish to request all users.
    ///
    open func requestAllUsers(on guildId: GuildID) {
        let requestObject: [String: Any] = [
            "guild_id": guildId,
            "query": "",
            "limit": 0
        ]

        guard let shardNum = guilds[guildId]?.shardNumber(assuming: shards) else { return }

        shardManager.sendPayload(DiscordGatewayPayload(code: .gateway(.requestGuildMembers),
                                                       payload: .object(requestObject)),
                                 onShard: shardNum)
    }

    ///
    /// Sets the user's presence.
    ///
    /// - parameter presence: The new presence object
    ///
    open func setPresence(_ presence: DiscordPresenceUpdate) {
        shardManager.sendPayload(DiscordGatewayPayload(code: .gateway(.statusUpdate),
                                                       payload: .object(presence.json)),
                                 onShard: 0)
    }

    private func startVoiceConnection(_ guildId: GuildID) {
        voiceManager.startVoiceConnection(guildId)
    }

    // MARK: DiscordShardManagerDelegate conformance.

    ///
    /// Signals that the manager has finished connecting.
    ///
    /// - parameter manager: The manager.
    /// - parameter didConnect: Should always be true.
    ///
    open func shardManager(_ manager: DiscordShardManager, didConnect connected: Bool) {
        handleQueue.async {
            self.connected = true

            self.delegate?.client(self, didConnect: true)
        }
    }

    ///
    /// Signals that the manager has disconnected.
    ///
    /// - parameter manager: The manager.
    /// - parameter didDisconnectWithReason: The reason the manager disconnected.
    ///
    open func shardManager(_ manager: DiscordShardManager, didDisconnectWithReason reason: String) {
        handleQueue.async {
            self.connected = false

            self.delegate?.client(self, didDisconnectWithReason: reason)
        }
    }

    ///
    /// Signals that the manager received an event. The client should handle this.
    ///
    /// - parameter manager: The manager.
    /// - parameter shouldHandleEvent: The event to be handled.
    /// - parameter withPayload: The payload that came with the event.
    ///
    open func shardManager(_ manager: DiscordShardManager, shouldHandleEvent event: DiscordDispatchEvent,
                           withPayload payload: DiscordGatewayPayload) {
        handleQueue.async {
            self.handleDispatch(event: event, data: payload.payload)
        }
    }

    ///
    /// Called when an engine disconnects.
    ///
    /// - parameter manager: The manager.
    /// - parameter engine: The engine that disconnected.
    ///
    open func voiceManager(_ manager: DiscordVoiceManager, didDisconnectEngine engine: DiscordVoiceEngine) {
        handleQueue.async {
            guard let shardNum = self.guilds[engine.guildId]?.shardNumber(assuming: self.shards) else { return }

            let payload = DiscordGatewayPayloadData.object(["guild_id": String(describing: engine.guildId),
                                                            "channel_id": NSNull(),
                                                            "self_mute": false,
                                                            "self_deaf": false])

            self.shardManager.sendPayload(DiscordGatewayPayload(code: .gateway(.voiceStatusUpdate), payload: payload),
                                          onShard: shardNum)
        }
    }

    ///
    /// Called when a voice engine receives voice data.
    ///
    /// - parameter manager: The manager.
    /// - parameter didReceiveVoiceData: The data received.
    /// - parameter fromEngine: The engine that received the data.
    ///
    open func voiceManager(_ manager: DiscordVoiceManager, didReceiveVoiceData data: DiscordVoiceData,
                           fromEngine engine: DiscordVoiceEngine) {
        voiceQueue.async {
            self.delegate?.client(self, didReceiveVoiceData: data, fromEngine: engine)
        }
    }

    ///
    /// Called when a voice engine needs an encoder.
    ///
    /// **Not called on the handleQueue**
    ///
    /// - parameter manager: The manager that is requesting an encoder.
    /// - parameter needsEncoderForEngine_: The engine that needs an encoder
    /// - returns: An encoder.
    ///
    open func voiceManager(_ manager: DiscordVoiceManager,
                           needsEncoderForEngine engine: DiscordVoiceEngine) throws -> DiscordVoiceEncoder? {
        return try delegate?.client(self, needsVoiceEncoderForEngine: engine)
    }

    ///
    /// Called when a voice engine is ready.
    ///
    /// - parameter manager: The manager.
    /// - parameter engine: The engine that's ready.
    /// *
    open func voiceManager(_ manager: DiscordVoiceManager, engineIsReady engine: DiscordVoiceEngine) {
        handleQueue.async {
            self.delegate?.client(self, isReadyToSendVoiceWithEngine: engine)
        }
    }

    // MARK: DiscordDispatchEventHandler Conformance

    ///
    /// Handles channel creates from Discord. You shouldn't need to call this method directly.
    ///
    /// Override to provide additional customization around this event.
    ///
    /// Calls the `didCreateChannel` delegate method.
    ///
    /// - parameter with: The data from the event
    ///
    open func handleChannelCreate(with data: [String: Any]) {
        DefaultDiscordLogger.Logger.log("Handling channel create", type: logType)

        guard let channel = channelFromObject(data, withClient: self) else { return }

        switch channel {
        case let guildChannel as DiscordGuildChannel:
            guilds[guildChannel.guildId]?.channels[guildChannel.id] = guildChannel
        case let dmChannel as DiscordDMChannel:
            directChannels[channel.id] = dmChannel
        case let groupChannel as DiscordGroupDMChannel:
            directChannels[channel.id] = groupChannel
        default:
            break
        }

        DefaultDiscordLogger.Logger.verbose("Created channel: \(channel)", type: logType)

        delegate?.client(self, didCreateChannel: channel)
    }

    ///
    /// Handles channel deletes from Discord. You shouldn't need to call this method directly.
    ///
    /// Override to provide additional customization around this event.
    ///
    /// Calls the `didDeleteChannel` delegate method.
    ///
    /// - parameter with: The data from the event
    ///
    open func handleChannelDelete(with data: [String: Any]) {
        DefaultDiscordLogger.Logger.log("Handling channel delete", type: logType)

        guard let type = DiscordChannelType(rawValue: data["type"] as? Int ?? -1) else { return }
        guard let channelId = Snowflake(data["id"] as? String) else { return }

        let removedChannel: DiscordChannel

        if type == .text || type == .voice, let guildId = Snowflake(data["guild_id"] as? String),
           let guildChannel = guilds[guildId]?.channels.removeValue(forKey: channelId) {
            removedChannel = guildChannel
        } else if type == .direct || type == .groupDM, let direct = directChannels.removeValue(forKey: channelId) {
            removedChannel = direct
        } else {
            return
        }

        channelCache.removeValue(forKey: channelId)

        DefaultDiscordLogger.Logger.verbose("Removed channel: \(removedChannel)", type: logType)

        delegate?.client(self, didDeleteChannel: removedChannel)
    }

    ///
    /// Handles channel updates from Discord. You shouldn't need to call this method directly.
    ///
    /// Override to provide additional customization around this event.
    ///
    /// Calls the `didUpdateChannel` delegate method.
    ///
    /// - parameter with: The data from the event
    ///
    open func handleChannelUpdate(with data: [String: Any]) {
        DefaultDiscordLogger.Logger.log("Handling channel update", type: logType)

        let channel = guildChannelFromObject(data, guildID: nil, client: self)

        DefaultDiscordLogger.Logger.verbose("Updated channel: \(channel)", type: logType)

        guilds[channel.guildId]?.channels[channel.id] = channel

        channelCache.removeValue(forKey: channel.id)

        delegate?.client(self, didUpdateChannel: channel)
    }

    ///
    /// Handles guild creates from Discord. You shouldn't need to call this method directly.
    ///
    /// Override to provide additional customization around this event.
    ///
    /// Calls the `didCreateGuild` delegate method.
    ///
    /// - parameter with: The data from the event
    ///
    open func handleGuildCreate(with data: [String: Any]) {
        DefaultDiscordLogger.Logger.log("Handling guild create", type: logType)

        let guild = DiscordGuild(guildObject: data, client: self)

        DefaultDiscordLogger.Logger.verbose("Created guild: \(guild)", type: self.logType)

        guilds[guild.id] = guild

        delegate?.client(self, didCreateGuild: guild)

        guard fillLargeGuilds && guild.large else { return }

        // Fill this guild with users immediately
        DefaultDiscordLogger.Logger.debug("Fill large guild \(guild.id) with all users", type: logType)

        requestAllUsers(on: guild.id)
    }

    ///
    /// Handles guild deletes from Discord. You shouldn't need to call this method directly.
    ///
    /// Override to provide additional customization around this event.
    ///
    /// Calls the `didDeleteGuild` delegate method.
    ///
    /// - parameter with: The data from the event
    ///
    open func handleGuildDelete(with data: [String: Any]) {
        DefaultDiscordLogger.Logger.log("Handling guild delete", type: logType)

        guard let guildId = Snowflake(data["id"] as? String) else { return }
        guard let removedGuild = guilds.removeValue(forKey: guildId) else { return }

        for channel in removedGuild.channels.keys {
            channelCache[channel] = nil
        }

        DefaultDiscordLogger.Logger.verbose("Removed guild: \(removedGuild)", type: logType)

        delegate?.client(self, didDeleteGuild: removedGuild)
    }

    ///
    /// Handles guild emoji updates from Discord. You shouldn't need to call this method directly.
    ///
    /// Override to provide additional customization around this event.
    ///
    /// Calls the `didUpdateEmojis:onGuild:` delegate method.
    ///
    /// - parameter with: The data from the event
    ///
    open func handleGuildEmojiUpdate(with data: [String: Any]) {
        DefaultDiscordLogger.Logger.log("Handling guild emoji update", type: logType)

        guard let guildId = Snowflake(data["guild_id"] as? String), let guild = guilds[guildId] else { return }
        guard let emojis = data["emojis"] as? [[String: Any]] else { return }

        let discordEmojis = DiscordEmoji.emojisFromArray(emojis)

        DefaultDiscordLogger.Logger.verbose("Created guild emojis: \(discordEmojis)", type: logType)

        guild.emojis = discordEmojis

        delegate?.client(self, didUpdateEmojis: discordEmojis, onGuild: guild)
    }

    ///
    /// Handles guild member adds from Discord. You shouldn't need to call this method directly.
    ///
    /// Override to provide additional customization around this event.
    ///
    /// Calls the `didAddGuildMember` delegate method.
    ///
    /// - parameter with: The data from the event
    ///
    open func handleGuildMemberAdd(with data: [String: Any]) {
        DefaultDiscordLogger.Logger.log("Handling guild member add", type: logType)

        guard let guildId = Snowflake(data["guild_id"] as? String), let guild = guilds[guildId] else { return }

        let guildMember = DiscordGuildMember(guildMemberObject: data, guildId: guild.id, guild: guild)

        DefaultDiscordLogger.Logger.verbose("Created guild member: \(guildMember)", type: logType)

        guild.members[guildMember.user.id] = guildMember
        guild.memberCount += 1

        delegate?.client(self, didAddGuildMember: guildMember)
    }

    ///
    /// Handles guild member removes from Discord. You shouldn't need to call this method directly.
    ///
    /// Override to provide additional customization around this event.
    ///
    /// Calls the `didRemoveGuildMember` delegate method.
    ///
    /// - parameter with: The data from the event
    ///
    open func handleGuildMemberRemove(with data: [String: Any]) {
        DefaultDiscordLogger.Logger.log("Handling guild member remove", type: logType)

        guard let guildId = Snowflake(data["guild_id"] as? String), let guild = guilds[guildId] else { return }
        guard let user = data["user"] as? [String: Any], let id = Snowflake(user["id"] as? String) else { return }

        guild.memberCount -= 1

        guard let removedGuildMember = guild.members.removeValue(forKey: id) else { return }

        DefaultDiscordLogger.Logger.verbose("Removed guild member: \(removedGuildMember)", type: logType)

        delegate?.client(self, didRemoveGuildMember: removedGuildMember)
    }

    ///
    /// Handles guild member updates from Discord. You shouldn't need to call this method directly.
    ///
    /// Override to provide additional customization around this event.
    ///
    /// Calls the `didUpdateGuildMember` delegate method.
    ///
    /// - parameter with: The data from the event
    ///
    open func handleGuildMemberUpdate(with data: [String: Any]) {
        DefaultDiscordLogger.Logger.log("Handling guild member update", type: logType)

        guard let guildId = Snowflake(data["guild_id"] as? String), let guild = guilds[guildId] else { return }
        guard let user = data["user"] as? [String: Any], let id = Snowflake(user["id"] as? String) else { return }
        guard let guildMember = guild.members[id]?.updateMember(data) else { return }

        DefaultDiscordLogger.Logger.verbose("Updated guild member: \(guildMember)", type: logType)

        delegate?.client(self, didUpdateGuildMember: guildMember)
    }

    ///
    /// Handles guild members chunks from Discord. You shouldn't need to call this method directly.
    ///
    /// Override to provide additional customization around this event.
    ///
    /// Calls the `didHandleGuildMemberChunk:forGuild:` delegate method.
    ///
    /// - parameter with: The data from the event
    ///
    open func handleGuildMembersChunk(with data: [String: Any]) {
        DefaultDiscordLogger.Logger.log("Handling guild members chunk", type: logType)

        guard let guildId = Snowflake(data["guild_id"] as? String), let guild = guilds[guildId] else { return }
        guard let members = data["members"] as? [[String: Any]] else { return }

        let guildMembers = DiscordGuildMember.guildMembersFromArray(members, withGuildId: guildId, guild: guild)

        guild.members.updateValues(withOtherDict: guildMembers)

        delegate?.client(self, didHandleGuildMemberChunk: guildMembers, forGuild: guild)
    }

    ///
    /// Handles guild role creates from Discord. You shouldn't need to call this method directly.
    ///
    /// Override to provide additional customization around this event.
    ///
    /// Calls the `didCreateRole` delegate method.
    ///
    /// - parameter with: The data from the event
    ///
    open func handleGuildRoleCreate(with data: [String: Any]) {
        DefaultDiscordLogger.Logger.log("Handling guild role create", type: logType)

        guard let guildId = Snowflake(data["guild_id"] as? String), let guild = guilds[guildId] else { return }
        guard let roleObject = data["role"] as? [String: Any] else { return }
        let role = DiscordRole(roleObject: roleObject)

        DefaultDiscordLogger.Logger.verbose("Created role: \(role)", type: logType)

        guild.roles[role.id] = role

        delegate?.client(self, didCreateRole: role, onGuild: guild)
    }

    ///
    /// Handles guild role removes from Discord. You shouldn't need to call this method directly.
    ///
    /// Override to provide additional customization around this event.
    ///
    /// Calls the `didDeleteRole` delegate method.
    ///
    /// - parameter with: The data from the event
    ///
    open func handleGuildRoleRemove(with data: [String: Any]) {
        DefaultDiscordLogger.Logger.log("Handling guild role remove", type: logType)

        guard let guildId = Snowflake(data["guild_id"] as? String), let guild = guilds[guildId] else { return }
        guard let roleId = Snowflake(data["role_id"] as? String) else { return }
        guard let removedRole = guild.roles.removeValue(forKey: roleId) else { return }

        DefaultDiscordLogger.Logger.verbose("Removed role: \(removedRole)", type: logType)

        delegate?.client(self, didDeleteRole: removedRole, fromGuild: guild)
    }

    ///
    /// Handles guild member updates from Discord. You shouldn't need to call this method directly.
    ///
    /// Override to provide additional customization around this event.
    ///
    /// Calls the `didUpdateRole` delegate method.
    ///
    /// - parameter with: The data from the event
    ///
    open func handleGuildRoleUpdate(with data: [String: Any]) {
        DefaultDiscordLogger.Logger.log("Handling guild role update", type: logType)

        // Functionally the same as adding
        guard let guildId = Snowflake(data["guild_id"] as? String), let guild = guilds[guildId] else { return }
        guard let roleObject = data["role"] as? [String: Any] else { return }
        let role = DiscordRole(roleObject: roleObject)

        DefaultDiscordLogger.Logger.verbose("Updated role: \(role)", type: logType)

        guild.roles[role.id] = role

        delegate?.client(self, didUpdateRole: role, onGuild: guild)
    }

    ///
    /// Handles guild updates from Discord. You shouldn't need to call this method directly.
    ///
    /// Override to provide additional customization around this event.
    ///
    /// Calls the `didUpdateGuild` delegate method.
    ///
    /// - parameter with: The data from the event
    ///
    open func handleGuildUpdate(with data: [String: Any]) {
        DefaultDiscordLogger.Logger.log("Handling guild update", type: logType)

        guard let guildId = Snowflake(data["id"] as? String) else { return }
        guard let updatedGuild = guilds[guildId]?.updateGuild(fromGuildUpdate: data) else { return }

        DefaultDiscordLogger.Logger.verbose("Updated guild: \(updatedGuild)", type: logType)

        delegate?.client(self, didUpdateGuild: updatedGuild)
    }

    ///
    /// Handles message updates from Discord. You shouldn't need to call this method directly.
    ///
    /// Override to provide additional customization around this event.
    ///
    /// Calls the `didUpdateMessage` delegate method.
    ///
    /// - parameter with: The data from the event
    ///
    open func handleMessageUpdate(with data: [String: Any]) {
        DefaultDiscordLogger.Logger.log("Handling message update", type: logType)

        let message = DiscordMessage(messageObject: data, client: self)

        DefaultDiscordLogger.Logger.verbose("Message: \(message)", type: logType)

        delegate?.client(self, didUpdateMessage: message)
    }

    ///
    /// Handles message creates from Discord. You shouldn't need to call this method directly.
    ///
    /// Override to provide additional customization around this event.
    ///
    /// Calls the `didCreateMessage` delegate method.
    ///
    /// - parameter with: The data from the event
    ///
    open func handleMessageCreate(with data: [String: Any]) {
        DefaultDiscordLogger.Logger.log("Handling message create", type: logType)

        let message = DiscordMessage(messageObject: data, client: self)

        DefaultDiscordLogger.Logger.verbose("Message: \(message)", type: logType)

        delegate?.client(self, didCreateMessage: message)
    }

    ///
    /// Handles presence updates from Discord. You shouldn't need to call this method directly.
    ///
    /// Override to provide additional customization around this event.
    ///
    /// Calls the `didReceivePresenceUpdate` delegate method.
    ///
    /// - parameter with: The data from the event
    ///
    open func handlePresenceUpdate(with data: [String: Any]) {
        guard let guildId = Snowflake(data["guild_id"] as? String), let guild = guilds[guildId] else { return }
        guard let user = data["user"] as? [String: Any], let userId = Snowflake(user["id"] as? String) else { return }

        var presence = guild.presences[userId]

        if presence != nil {
            presence!.updatePresence(presenceObject: data)
        } else {
            presence = DiscordPresence(presenceObject: data, guildId: guildId)
        }

        if !discardPresences {
            DefaultDiscordLogger.Logger.debug("Updated presence: \(presence!)", type: logType)

            guild.presences[userId] = presence!
        }

        delegate?.client(self, didReceivePresenceUpdate: presence!)

        guild.updateGuild(fromPresence: presence!, fillingUsers: fillUsers, pruningUsers: pruneUsers)
    }

    ///
    /// Handles the ready event from Discord. You shouldn't need to call this method directly.
    ///
    /// Override to provide additional customization around this event.
    ///
    /// Calls the `didReceiveReady` delegate method.
    ///
    /// - parameter with: The data from the event
    ///
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

    ///
    /// Handles voice server updates from Discord. You shouldn't need to call this method directly.
    ///
    /// Override to provide additional customization around this event.
    ///
    /// - parameter with: The data from the event
    /// *
    open func handleVoiceServerUpdate(with data: [String: Any]) {
        DefaultDiscordLogger.Logger.log("Handling voice server update", type: logType)
        DefaultDiscordLogger.Logger.verbose("Voice server update: \(data)", type: logType)

        let info = DiscordVoiceServerInformation(voiceServerInformationObject: data)

        voiceManager.voiceServerInformations[info.guildId] = info

        self.startVoiceConnection(info.guildId)
    }

    ///
    /// Handles voice state updates from Discord. You shouldn't need to call this method directly.
    ///
    /// Override to provide additional customization around this event.
    ///
    /// Calls the `didReceiveVoiceStateUpdate` delegate method.
    ///
    /// - parameter with: The data from the event
    ///
    open func handleVoiceStateUpdate(with data: [String: Any]) {
        DefaultDiscordLogger.Logger.log("Handling voice state update", type: logType)

        guard let guildId = Snowflake(data["guild_id"] as? String) else { return }

        let state = DiscordVoiceState(voiceStateObject: data, guildId: guildId)

        DefaultDiscordLogger.Logger.verbose("Voice state: \(state)", type: logType)

        if state.channelId == 0 {
            guilds[guildId]?.voiceStates[state.userId] = nil
        } else {
            guilds[guildId]?.voiceStates[state.userId] = state
        }

        if state.userId == user?.id {
            if state.channelId == 0 {
                voiceManager.protected { self.voiceManager.voiceStates[state.guildId] = nil }
            } else {
                voiceManager.protected { self.voiceManager.voiceStates[state.guildId] = state }

                startVoiceConnection(state.guildId)
            }
        }

        delegate?.client(self, didReceiveVoiceStateUpdate: state)
    }
}
