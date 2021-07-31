// The MIT License (MIT)
// Copyright (c) 2016 Erik Little
// Copyright (c) 2021 fwcd

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
import Logging
import NIO

fileprivate let logger = Logger(label: "DiscordClient")

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
public class DiscordClient: DiscordShardManagerDelegate, DiscordUserActor, DiscordEndpointConsumer {
    // MARK: Properties

    /// The rate limiter for this client.
    public var rateLimiter: DiscordRateLimiterSpec!

    /// The run loops.
    public let runloops = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)

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
    public var shardingInfo = try! DiscordShardInformation(shardRange: 0..<1, totalShards: 1)

    /// The gateway intents.
    public var intents = DiscordGatewayIntents.unprivilegedIntents

    /// Whether large guilds should have their users fetched as soon as they are created.
    public var fillLargeGuilds = false

    /// Whether the client should query the API for users who aren't in the guild
    public var fillUsers = false

    /// Whether the client should remove users from guilds when they go offline.
    public var pruneUsers = false

    /// Whether or not this client is connected.
    public private(set) var connected = false

    /// The direct message channels this user is in.
    public private(set) var directChannels = DiscordIDDictionary<DiscordChannel>()

    /// The guilds that this user is in.
    public private(set) var guilds = DiscordIDDictionary<DiscordGuild>()

    /// The DiscordUser this client is connected to.
    public private(set) var user: DiscordUser?

    var channelCache = DiscordIDDictionary<DiscordChannel>()

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
        self.delegate = delegate

        for config in configuration {
            switch config {
            case let .handleQueue(queue):
                handleQueue = queue
            case let .rateLimiter(limiter):
                self.rateLimiter = limiter
            case let .shardingInfo(shardingInfo):
                self.shardingInfo = shardingInfo
            case let .intents(intents):
                self.intents = intents
            case .discardPresences:
                discardPresences = true
            case .fillLargeGuilds:
                fillLargeGuilds = true
            case .fillUsers:
                fillUsers = true
            case .pruneUsers:
                pruneUsers = true
            }
        }

        rateLimiter = rateLimiter ?? DiscordRateLimiter(callbackQueue: handleQueue, failFast: false)
    }

    deinit {
        try! runloops.syncShutdownGracefully()
    }

    // MARK: Methods

    ///
    /// Begins the connection to Discord. Once this is called, wait for a `connect` event before trying to interact
    /// with the client.
    ///
    public func connect() {
        logger.info("Connecting")

        shardManager.manuallyShatter(withInfo: shardingInfo, intents: intents)
        shardManager.connect()
    }

    ///
    /// Disconnects from Discord. A `disconnect` event is fired when the client has successfully disconnected.
    ///
    /// Calling this method turns off automatic resuming, set `resume` to `true` before calling `connect()` again.
    ///
    public func disconnect() {
        logger.info("Disconnecting")

        connected = false

        shardManager.disconnect()
    }

    ///
    /// Finds a channel by its snowflake.
    ///
    /// - parameter fromId: A channel snowflake
    /// - returns: An optional containing a `DiscordChannel` if one was found.
    ///
    public func findChannel(fromId channelId: ChannelID) -> DiscordChannel? {
        if let channel = channelCache[channelId] {
            logger.debug("Got cached channel \(channel)")

            return channel
        }

        let channel: DiscordChannel

        if let guild = guildForChannel(channelId), let guildChannel = guild.channels[channelId] {
            channel = guildChannel
        } else if let dmChannel = directChannels[channelId] {
            channel = dmChannel
        } else {
            logger.debug("Couldn't find channel \(channelId)")

            return nil
        }

        channelCache[channel.id] = channel

        logger.debug("Found channel \(channel)")

        return channel
    }

    // Handling

    ///
    /// Handles a dispatch event. This will call one of the other handle methods or the standard event handler.
    ///
    /// - parameter event: The dispatch event
    ///
    private func handleDispatch(event: DiscordDispatchEvent) {
        switch event {
        case .presenceUpdate(let e): handlePresenceUpdate(with: e)
        case .messageCreate(let e): handleMessageCreate(with: e)
        case .messageUpdate(let e): handleMessageUpdate(with: e)
        case .messageReactionAdd(let e): handleMessageReactionAdd(with: e)
        case .messageReactionRemove(let e): handleMessageReactionRemove(with: e)
        case .messageReactionRemoveAll(let e): handleMessageReactionRemoveAll(with: e)
        case .guildMemberAdd(let e): handleGuildMemberAdd(with: e)
        case .guildMembersChunk(let e): handleGuildMembersChunk(with: e)
        case .guildMemberUpdate(let e): handleGuildMemberUpdate(with: e)
        case .guildMemberRemove(let e): handleGuildMemberRemove(with: e)
        case .guildRoleCreate(let e): handleGuildRoleCreate(with: e)
        case .guildRoleDelete(let e): handleGuildRoleDelete(with: e)
        case .guildRoleUpdate(let e): handleGuildRoleUpdate(with: e)
        case .guildCreate(let e): handleGuildCreate(with: e)
        case .guildDelete(let e): handleGuildDelete(with: e)
        case .guildUpdate(let e): handleGuildUpdate(with: e)
        case .guildEmojisUpdate(let e): handleGuildEmojiUpdate(with: e)
        case .channelUpdate(let e): handleChannelUpdate(with: e)
        case .channelCreate(let e): handleChannelCreate(with: e)
        case .channelDelete(let e): handleChannelDelete(with: e)
        case .voiceStateUpdate(let e): handleVoiceStateUpdate(with: e)
        case .interactionCreate(let e): handleInteractionCreate(with: e)
        case .ready(let e): handleReady(with: e)
        default: delegate?.client(self, didNotHandleDispatchEvent: event)
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
    /// Requests all users from Discord for the guild specified. Use this when you need to get all users on a large
    /// guild. Multiple `guildMembersChunk` will be fired.
    ///
    /// - parameter on: The snowflake of the guild you wish to request all users.
    ///
    public func requestAllUsers(on guildId: GuildID) {
        let request = DiscordGatewayRequestGuildMembers(
            guildId: guildId,
            query: "",
            limit: 0
        )

        guard let shardNum = guilds[guildId]?.shardNumber(assuming: shardingInfo.totalShards) else { return }

        shardManager.sendPayload(.requestGuildMembers(request), onShard: shardNum)
    }

    ///
    /// Sets the user's presence.
    ///
    /// - parameter presence: The new presence object
    ///
    public func setPresence(_ presence: DiscordPresenceUpdate) {
        shardManager.sendPayload(.presenceUpdate(presence), onShard: 0)
    }

    // MARK: DiscordShardManagerDelegate conformance.

    ///
    /// Signals that the manager has finished connecting.
    ///
    /// - parameter manager: The manager.
    /// - parameter didConnect: Should always be true.
    ///
    public func shardManager(_ manager: DiscordShardManager, didConnect connected: Bool) {
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
    public func shardManager(_ manager: DiscordShardManager, didDisconnectWithReason reason: String) {
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
    ///
    public func shardManager(_ manager: DiscordShardManager, shouldHandleEvent event: DiscordDispatchEvent) {
        handleQueue.async {
            self.handleDispatch(event: event)
        }
    }

    ///
    /// Handles channel creates from Discord. You shouldn't need to call this method directly.
    ///
    /// Calls the `didCreateChannel` delegate method.
    ///
    /// - parameter with: The data from the event
    ///
    private func handleChannelCreate(with channel: DiscordChannel) {
        logger.info("Handling channel create")

        if channel.isDM {
            directChannels[channel.id] = channel
        } else if let guildId = channel.guildId {
            guilds[guildId]?.channels[channel.id] = channel
        }

        logger.debug("(verbose) Created channel: \(channel)")

        delegate?.client(self, didCreateChannel: channel)
    }

    ///
    /// Handles channel deletes from Discord. You shouldn't need to call this method directly.
    ///
    /// Calls the `didDeleteChannel` delegate method.
    ///
    /// - parameter with: The data from the event
    ///
    private func handleChannelDelete(with channel: DiscordChannel) {
        logger.info("Handling channel delete")

        channelCache.removeValue(forKey: channel.id)

        logger.debug("(verbose) Removed channel: \(channel)")

        delegate?.client(self, didDeleteChannel: channel)
    }

    ///
    /// Handles voice state updates from Discord. You shouldn't need to call this method directly.
    ///
    /// Calls the `didReceiveVoiceStateUpdate` delegate method.
    ///
    /// - parameter with: The data from the event
    ///
    private func handleVoiceStateUpdate(with state: DiscordVoiceState) {
        logger.info("Handling voice state update")

        guard let guildId = state.guildId,
              var guild = guilds[guildId] else { return }

        logger.debug("Voice state: \(state)")

        if state.channelId == 0 {
            guild.voiceStates[state.userId] = nil
        } else {
            guild.voiceStates[state.userId] = state
        }

        guilds[guildId] = guild

        delegate?.client(self, didReceiveVoiceStateUpdate: state)
    }

    ///
    /// Handles channel updates from Discord. You shouldn't need to call this method directly.
    ///
    /// Calls the `didUpdateChannel` delegate method.
    ///
    /// - parameter with: The data from the event
    ///
    private func handleChannelUpdate(with channel: DiscordChannel) {
        logger.info("Handling channel update")

        guard let guildId = channel.guildId else { return }
        guilds[guildId]?.channels[channel.id] = channel

        channelCache.removeValue(forKey: channel.id)

        logger.debug("(verbose) Updated channel: \(channel)")

        delegate?.client(self, didUpdateChannel: channel)
    }

    ///
    /// Handles guild creates from Discord. You shouldn't need to call this method directly.
    ///
    /// Calls the `didCreateGuild` delegate method.
    ///
    /// - parameter with: The data from the event
    ///
    private func handleGuildCreate(with guild: DiscordGuild) {
        logger.info("Handling guild create")

        guilds[guild.id] = guild

        logger.debug("(verbose) Created guild: \(guild)")

        delegate?.client(self, didCreateGuild: guild)

        guard fillLargeGuilds && (guild.large ?? false) else { return }

        // Fill this guild with users immediately
        logger.debug("Fill large guild \(guild.id) with all users")

        requestAllUsers(on: guild.id)
    }

    ///
    /// Handles guild deletes from Discord. You shouldn't need to call this method directly.
    ///
    /// Calls the `didDeleteGuild` delegate method.
    ///
    /// - parameter with: The data from the event
    ///
    private func handleGuildDelete(with guild: DiscordGuild) {
        logger.info("Handling guild delete")

        let removedGuild = guilds.removeValue(forKey: guild.id) ?? guild

        for channel in removedGuild.channels.keys {
            channelCache[channel] = nil
        }

        logger.debug("(verbose) Removed guild: \(removedGuild)")

        delegate?.client(self, didDeleteGuild: removedGuild)
    }

    ///
    /// Handles guild emoji updates from Discord. You shouldn't need to call this method directly.
    ///
    /// Calls the `didUpdateEmojis:onGuild:` delegate method.
    ///
    /// - parameter with: The data from the event
    ///
    private func handleGuildEmojiUpdate(with event: DiscordGuildEmojisUpdateEvent) {
        logger.info("Handling guild emoji update")

        guard var guild = guilds[event.guildId] else { return }
        guild.emojis = .init(event.emojis)
        guilds[event.guildId] = guild

        logger.debug("(verbose) Created guild emojis: \(event.emojis)")

        delegate?.client(self, didUpdateEmojis: event.emojis, onGuild: guild)
    }

    ///
    /// Handles guild member adds from Discord. You shouldn't need to call this method directly.
    ///
    /// Calls the `didAddGuildMember` delegate method.
    ///
    /// - parameter with: The data from the event
    ///
    private func handleGuildMemberAdd(with member: DiscordGuildMember) {
        logger.info("Handling guild member add")

        guard var guild = guilds[member.guildId] else { return }
        guild.members[member.id] = member
        guild.memberCount = guild.members.count
        guilds[member.guildId] = guild

        logger.debug("(verbose) Created guild member: \(member)")

        delegate?.client(self, didAddGuildMember: member)
    }

    ///
    /// Handles guild member removes from Discord. You shouldn't need to call this method directly.
    ///
    /// Calls the `didRemoveGuildMember` delegate method.
    ///
    /// - parameter with: The data from the event
    ///
    private func handleGuildMemberRemove(with event: DiscordGuildMemberRemoveEvent) {
        logger.info("Handling guild member remove")

        guard var guild = guilds[event.guildId] else { return }
        let removedMember = guild.members.removeValue(forKey: event.user.id)
        guild.memberCount = guild.members.count
        guilds[event.guildId] = guild

        guard let removedMember = removedMember else { return }

        logger.debug("(verbose) Removed guild member: \(removedMember)")

        delegate?.client(self, didRemoveGuildMember: removedMember)
    }

    ///
    /// Handles guild member updates from Discord. You shouldn't need to call this method directly.
    ///
    /// Calls the `didUpdateGuildMember` delegate method.
    ///
    /// - parameter with: The data from the event
    ///
    private func handleGuildMemberUpdate(with member: DiscordGuildMember) {
        logger.info("Handling guild member update")

        guard var guild = guilds[member.guildId] else { return }
        guild.members[member.id] = member
        guilds[member.guildId] = guild

        logger.debug("(verbose) Updated guild member: \(member)")

        delegate?.client(self, didUpdateGuildMember: member)
    }

    ///
    /// Handles guild members chunks from Discord. You shouldn't need to call this method directly.
    ///
    /// Calls the `didHandleGuildMemberChunk:forGuild:` delegate method.
    ///
    /// - parameter with: The data from the event
    ///
    private func handleGuildMembersChunk(with event: DiscordGuildMembersChunkEvent) {
        logger.info("Handling guild members chunk")

        guard let guildId = event.guildId,
              var guild = guilds[guildId] else { return }
        guild.members.merge(event.members)
        guilds[guildId] = guild

        delegate?.client(self, didHandleGuildMemberChunk: event.members, forGuild: guild)
    }

    ///
    /// Handles guild role creates from Discord. You shouldn't need to call this method directly.
    ///
    /// Calls the `didCreateRole` delegate method.
    ///
    /// - parameter with: The data from the event
    ///
    private func handleGuildRoleCreate(with event: DiscordGuildRoleCreateEvent) {
        logger.info("Handling guild role create")

        guard var guild = guilds[event.guildId] else { return }
        guild.roles[event.role.id] = event.role
        guilds[event.guildId] = guild

        logger.debug("(verbose) Created role: \(event.role)")

        delegate?.client(self, didCreateRole: event.role, onGuild: guild)
    }

    ///
    /// Handles guild role removes from Discord. You shouldn't need to call this method directly.
    ///
    /// Calls the `didDeleteRole` delegate method.
    ///
    /// - parameter with: The data from the event
    ///
    private func handleGuildRoleDelete(with event: DiscordGuildRoleDeleteEvent) {
        logger.info("Handling guild role remove")

        guard var guild = guilds[event.guildId] else { return }
        let removedRole = guild.roles.removeValue(forKey: event.role.id) ?? event.role
        guilds[event.guildId] = guild

        logger.debug("(verbose) Removed role: \(removedRole)")

        delegate?.client(self, didDeleteRole: removedRole, fromGuild: guild)
    }

    ///
    /// Handles guild member updates from Discord. You shouldn't need to call this method directly.
    ///
    /// Calls the `didUpdateRole` delegate method.
    ///
    /// - parameter with: The data from the event
    ///
    private func handleGuildRoleUpdate(with event: DiscordGuildRoleUpdateEvent) {
        logger.info("Handling guild role update")

        // Functionally the same as adding
        logger.debug("(verbose) Updated role: \(event.role)")

        guard var guild = guilds[event.guildId] else { return }
        guild.roles[event.role.id] = event.role
        guilds[event.guildId] = guild

        delegate?.client(self, didUpdateRole: event.role, onGuild: guild)
    }

    ///
    /// Handles guild updates from Discord. You shouldn't need to call this method directly.
    ///
    /// Calls the `didUpdateGuild` delegate method.
    ///
    /// - parameter with: The data from the event
    ///
    private func handleGuildUpdate(with guild: DiscordGuild) {
        logger.info("Handling guild update")

        var updatedGuild = guilds[guild.id] ?? guild
        updatedGuild.merge(update: guild)
        guilds[guild.id] = updatedGuild

        logger.debug("(verbose) Updated guild: \(updatedGuild)")

        delegate?.client(self, didUpdateGuild: updatedGuild)
    }

    ///
    /// Handles message updates from Discord. You shouldn't need to call this method directly.
    ///
    /// Calls the `didUpdateMessage` delegate method.
    ///
    /// - parameter with: The data from the event
    ///
    private func handleMessageUpdate(with message: DiscordMessage) {
        logger.info("Handling message update")

        logger.debug("(verbose) Message: \(message)")

        delegate?.client(self, didUpdateMessage: message)
    }

    ///
    /// Handles message creates from Discord. You shouldn't need to call this method directly.
    ///
    /// Calls the `didCreateMessage` delegate method.
    ///
    /// - parameter with: The data from the event
    ///
    private func handleMessageCreate(with message: DiscordMessage) {
        logger.info("Handling message create")

        logger.debug("(verbose) Message: \(message)")

        delegate?.client(self, didCreateMessage: message)
    }

    ///
    /// Handles reaction adds from Discord. You shouldn't need to call this method directly.
    ///
    /// Calls the `didAddReaction` delegate method.
    ///
    /// - parameter with: The data from the event
    ///
    private func handleMessageReactionAdd(with event: DiscordMessageReactionAddEvent) {
        logger.info("Handling message reaction add")

        guard let channel = findChannel(fromId: event.channelId) else { return }

        if let guildId = event.guildId,
           let member = event.member {
            guilds[guildId]?.members[member.user.id] = member
        }

        delegate?.client(
            self,
            didAddReaction: event.emoji,
            toMessage: event.messageId,
            onChannel: channel,
            user: event.userId
        )
    }

    ///
    /// Handles reaction removals from Discord. You shouldn't need to call this method directly.
    ///
    /// Calls the `didRemoveReaction` delegate method.
    ///
    /// - parameter with: The data from the event
    ///
    private func handleMessageReactionRemove(with event: DiscordMessageReactionRemoveEvent) {
        logger.info("Handling message reaction remove")

        guard let channel = findChannel(fromId: event.channelId) else { return }

        delegate?.client(
            self,
            didRemoveReaction: event.emoji,
            fromMessage: event.messageId,
            onChannel: channel,
            user: event.userId
        )
    }

    ///
    /// Handles reaction remove alls from Discord. You shouldn't need to call this method directly.
    ///
    /// Calls the `didRemoveAllReactionsFrom` delegate method.
    ///
    /// - parameter with: The data from the event
    ///
    private func handleMessageReactionRemoveAll(with event: DiscordMessageReactionRemoveAllEvent) {
        guard let channel = findChannel(fromId: event.channelId) else {
            logger.error("Failed to get channel from ID in reaction remove all")
            return
        }

        delegate?.client(self, didRemoveAllReactionsFrom: event.messageId, onChannel: channel)
    }

    ///
    /// Handles presence updates from Discord. You shouldn't need to call this method directly.
    ///
    /// Calls the `didReceivePresenceUpdate` delegate method.
    ///
    /// - parameter with: The data from the event
    ///
    private func handlePresenceUpdate(with update: DiscordPresenceUpdateEvent) {
        guard let guildId = update.guildId,
              var guild = guilds[guildId] else { return }

        var presence = guild.presences[update.user.id] ?? update
        presence.merge(update: update)

        if !discardPresences {
            logger.debug("Updated presence: \(presence)")

            guild.presences[update.user.id] = presence
        }

        // TODO: Do we need to update the guild from the presences too?

        guilds[guildId] = guild

        delegate?.client(self, didReceivePresenceUpdate: presence)
    }

    ///
    /// Handles interaction creations from Discord, i.e. slash command
    /// invocations. You shouldn't need to call this method directly.
    ///
    /// Calls the `didCreateInteraction` delegate method.
    ///
    /// - parameter with: The data from the event
    ///
    private func handleInteractionCreate(with interaction: DiscordInteraction) {
        logger.info("Handling interaction create")

        delegate?.client(self, didCreateInteraction: interaction)
    }

    ///
    /// Handles the ready event from Discord. You shouldn't need to call this method directly.
    ///
    /// Calls the `didReceiveReady` delegate method.
    ///
    /// - parameter with: The data from the event
    ///
    private func handleReady(with event: DiscordReadyEvent) {
        logger.info("Handling ready")

        user = event.user

        // TODO: Handle uninitialized guilds?
        // TODO: Use private_channels?

        delegate?.client(self, didReceiveReady: event)
    }
}
