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

import class Dispatch.DispatchSemaphore
import Foundation

/// Represents a Guild.
public final class DiscordGuild : DiscordClientHolder, CustomStringConvertible {
	// MARK: Properties

	// TODO figure out what features are
	/// The guild's features.
	public let features: [Any]

	/// The snowflake id of the guild.
	public let id: String

	/// Whether or not this a "large" guild.
	public let large: Bool

	/// The date the user joined the guild.
	public let joinedAt: Date

	/// The base64 encoded splash image.
	public let splash: String

	/// Whether this guild is unavaiable.
	public let unavailable: Bool

	/// - returns: A description of this guild
	public var description: String {
		return "DiscordGuild(name: \(name))"
	}

	/// Reference to the client.
	public weak var client: DiscordClient?

	/// A dictionary of this guild's channels. The key is the snowflake id of the channel.
	public internal(set) var channels: [String: DiscordGuildChannel]

	/// A dictionary of this guild's emojis. The key is the snowflake id of the emoji.
	public internal(set) var emojis: [String: DiscordEmoji]

	/// The number of members in this guild.
	///
	/// *This number might not be the actual number of users in the `members` field.*
	public internal(set) var memberCount: Int

	/// A `DiscordLazyDictionary` of guild members. The key is the snowflake id of the user.
	public internal(set) var members: DiscordLazyDictionary<String, DiscordGuildMember>

	/// A `DiscordLazyDictionary` of presences. The key is the snowflake id of the user.
	public internal(set) var presences: DiscordLazyDictionary<String, DiscordPresence>

	/// A dictionary of this guild's roles. The key is the snowflake id of the role.
	public internal(set) var roles: [String: DiscordRole]

	/// A dictionary of this guild's current voice states. The key is the snowflake id of the user for this voice
	/// state.
	public internal(set) var voiceStates: [String: DiscordVoiceState]

	/// The default message notification setting.
	public private(set) var defaultMessageNotifications: Int

	/// The snowflake id of the embed channel for this guild.
	public private(set) var embedChannelId: String

	/// Whether this guild has embed enabled.
	public private(set) var embedEnabled: Bool

	/// The base64 encoded icon image for this guild.
	public private(set) var icon: String

	/// The multi-factor authentication level for this guild.
	public private(set) var mfaLevel: Int

	/// The name of this guild.
	public private(set) var name: String

	/// The snowflake id of this guild's owner.
	public private(set) var ownerId: String

	/// The region this guild is in.
	public private(set) var region: String

	/// The verification level a member of this guild must have to join.
	public private(set) var verificationLevel: Int

	init(guildObject: [String: Any], client: DiscordClient?) {
		channels = DiscordGuildChannel.guildChannelsFromArray(guildObject.get("channels", or: [[String: Any]]()),
			client: client)
		defaultMessageNotifications = guildObject.get("default_message_notifications", or: -1)
		embedEnabled = guildObject.get("embed_enabled", or: false)
		embedChannelId = guildObject.get("embed_channel_id", or: "")
		emojis = DiscordEmoji.emojisFromArray(guildObject.get("emojis", or: [[String: Any]]()))
		features = guildObject.get("features", or: [Any]())
		icon = guildObject.get("icon", or: "")
		id = guildObject.get("id", or: "")
		large = guildObject.get("large", or: false)
		memberCount = guildObject.get("member_count", or: 0)
		members = DiscordGuildMember.guildMembersFromArray(guildObject.get("members", or: [[String: Any]]()))
		mfaLevel = guildObject.get("mfa_level", or: -1)
		name = guildObject.get("name", or: "")
		ownerId = guildObject.get("owner_id", or: "")
		presences = DiscordPresence.presencesFromArray(guildObject.get("presences", or: [[String: Any]]()), guildId: id)
		region = guildObject.get("region", or: "")
		roles = DiscordRole.rolesFromArray(guildObject.get("roles", or: [[String: Any]]()))
		splash = guildObject.get("splash", or: "")
		verificationLevel = guildObject.get("verification_level", or: -1)
		voiceStates = DiscordVoiceState.voiceStatesFromArray(guildObject.get("voice_states", or: [[String: Any]]()),
			guildId: id)
		unavailable = guildObject.get("unavailable", or: false)
		joinedAt = convertISO8601(string: guildObject.get("joined_at", or: "")) ?? Date()
		self.client = client
	}

	// MARK: Methods

	/**
		Bans this user from the guild.

		- parameter member: The member to ban
		- parameter deleteMessageDays: The number of days going back to delete messages. Defaults to 7
	*/
	public func ban(_ member: DiscordGuildMember, deleteMessageDays: Int = 7) {
		guard let client = self.client else { return }

		client.guildBan(userId: member.user.id, on: id, deleteMessageDays: deleteMessageDays)
	}

	/**
		Creates a channel on this guild with `options`. The channel will not be immediately available; wait for a
		channel create event.

		- parameter with: The options for this new channel
	*/
	public func createChannel(with options: [DiscordEndpointOptions.GuildCreateChannel]) {
		guard let client = self.client else { return }

		DefaultDiscordLogger.Logger.log("Creating guild channel on %@", type: "DiscordGuild", args: id)

		client.createGuildChannel(on: id, options: options)
	}

	/**
		Gets the bans for this guild.

		**NOTE**: This is a blocking method. If you need an async version use the `getGuildBans` method from
		`DiscordEndpointConsumer`, which is available on `DiscordClient`.

		- returns: An array of `DiscordUser`s who are banned on this guild
	*/
	public func getBans() -> [DiscordBan] {
		guard let client = self.client else { return [] }

		let lock = DispatchSemaphore(value: 0)
		var bannedUsers: [DiscordBan]!

		client.getGuildBans(for: id) {bans in
			bannedUsers = bans

			lock.signal()
		}

		lock.wait()

		return bannedUsers
	}

	/**
		Gets a guild member by their user id.

		**NOTE**: This is a blocking method. If you need an async version user the `getGuildMember` method from
		`DiscordEndpointConsumer`, which is available on `DiscordClient`.

		- parameter userId: The user id of the member to get
		- returns: The guild member, if one was found
	*/
	public func getGuildMember(_ userId: String) -> DiscordGuildMember? {
		guard let client = self.client else { return nil }

		let lock = DispatchSemaphore(value: 0)
		var guildMember: DiscordGuildMember?

		client.getGuildMember(by: userId, on: id) {member in
			DefaultDiscordLogger.Logger.debug("Got member: %@", type: "DiscordGuild", args: userId)

			guildMember = member

			lock.signal()
		}

		lock.wait()

		return guildMember
	}

	// Used to setup initial guilds
	static func guildsFromArray(_ guilds: [[String: Any]], client: DiscordClient? = nil) -> [String: DiscordGuild] {
		var guildDictionary = [String: DiscordGuild]()

		for guildObject in guilds {
			let guild = DiscordGuild(guildObject: guildObject, client: client)

			guildDictionary[guild.id] = guild
		}

		return guildDictionary
	}

	/**
		Modifies this guild with `options`.

		- parameter options: An array of options to change
	*/
	public func modifyGuild(options: [DiscordEndpointOptions.ModifyGuild]) {
		guard let client = self.client else { return }

		client.modifyGuild(id, options: options)
	}

	func shardNumber(assuming numOfShards: Int) -> Int {
		return (Int(id)! >> 22) % numOfShards
	}


	// Used to update a guild from a guildUpdate event
	func updateGuild(with newGuild: [String: Any]) -> DiscordGuild {
		if let defaultMessageNotifications = newGuild["default_message_notifications"] as? Int {
			self.defaultMessageNotifications = defaultMessageNotifications
		}

		if let embedChannelId = newGuild["embed_channel_id"] as? String {
			self.embedChannelId = embedChannelId
		}

		if let embedEnabled = newGuild["embed_enabled"] as? Bool {
			self.embedEnabled = embedEnabled
		}

		if let icon = newGuild["icon"] as? String {
			self.icon = icon
		}

		if let memberCount = newGuild["member_count"] as? Int {
			self.memberCount = memberCount
		}

		if let mfaLevel = newGuild["mfa_level"] as? Int {
			self.mfaLevel = mfaLevel
		}

		if let name = newGuild["name"] as? String {
			self.name = name
		}

		if let ownerId = newGuild["owner_id"] as? String {
			self.ownerId = ownerId
		}

		if let region = newGuild["region"] as? String {
			self.region = region
		}

		if let verificationLevel = newGuild["verification_level"] as? Int {
			self.verificationLevel = verificationLevel
		}

		return self
	}

	/**
		Unbans the specified user from the guild.

		- parameter user: The user to unban
	*/
	public func unban(_ user: DiscordUser) {
		guard let client = self.client else { return }

		DefaultDiscordLogger.Logger.log("Unbanning user %@ on %@", type: "DiscordGuild", args: user, id)

		client.removeGuildBan(for: user.id, on: id)
	}
}
