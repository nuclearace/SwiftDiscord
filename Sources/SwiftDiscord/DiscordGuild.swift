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

public struct DiscordGuild {
	public let features: [Any] // TODO figure out what features are
	public let id: String
	public let large: Bool
	public let joinedAt: Date
	public let splash: String
	public let unavailable: Bool

	public private(set) var defaultMessageNotifications: Int
	public private(set) var embedChannelId: String
	public private(set) var embedEnabled: Bool
	public private(set) var icon: String
	public private(set) var memberCount: Int
	public private(set) var mfaLevel: Int
	public private(set) var name: String
	public private(set) var ownerId: String
	public private(set) var region: String
	public private(set) var verificationLevel: Int

	public var channels: [String: DiscordGuildChannel]
	public var emojis: [String: DiscordEmoji]
	public var members: [String: DiscordGuildMember]
	public var presences: [String: DiscordPresence]
	public var roles: [String: DiscordRole]
	public var voiceStates: [String: DiscordVoiceState]

	// Used to update a guild from a guildUpdate event
	mutating func updateGuild(with newGuild: [String: Any]) -> DiscordGuild {
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

	// Used to update a guild from a guildCreate event with data that come in after that create
	// Guild creation is currently slow, especially for large guilds with 12,000 Users + Presences
	// Guild creation currently happens off of the handleQueue, so that it doesn't block everything, however this means
	// that events for the guild currently being created are stored in the "shell" that's gotten in the ready event
	// So that we don't lose those updates, we need to play them back once the real guild is created
	mutating func updateGuild(from guild: DiscordGuild) {
		for (id, presence) in guild.presences {
			DefaultDiscordLogger.Logger.debug("Updating presence for user: %@", type: "DiscordGuild", args: id)

			presences[id] = presence
		}

		for (id, member) in guild.members {
			DefaultDiscordLogger.Logger.debug("Updating member: %@", type: "DiscordGuild", args: id)

			members[id] = member
		}

		for (id, role) in guild.roles {
			DefaultDiscordLogger.Logger.debug("Updating role: %@", type: "DiscordGuild", args: id)

			roles[id] = role
		}

		for (id, channel) in guild.channels {
			DefaultDiscordLogger.Logger.debug("Updating channel: %@", type: "DiscordGuild", args: id)

			channels[id] = channel
		}
	}
}

extension DiscordGuild {
	init(guildObject: [String: Any]) {
		let channels = DiscordGuildChannel.guildChannelsFromArray(guildObject.get("channels", or: [[String: Any]]()))
		let defaultMessageNotifications = guildObject.get("default_message_notifications", or: -1)
		let embedEnabled = guildObject.get("embed_enabled", or: false)
		let embedChannelId = guildObject.get("embed_channel_id", or: "")
		let emojis = DiscordEmoji.emojisFromArray(guildObject.get("emojis", or: [[String: Any]]()))
		let features = guildObject.get("features", or: [Any]())
		let icon = guildObject.get("icon", or: "")
		let id = guildObject.get("id", or: "")
		let large = guildObject.get("large", or: false)
		let memberCount = guildObject.get("member_count", or: 0)
		let members = DiscordGuildMember.guildMembersFromArray(guildObject.get("members", or: [[String: Any]]()))
		let mfaLevel = guildObject.get("mfa_level", or: -1)
		let name = guildObject.get("name", or: "")
		let ownerId = guildObject.get("owner_id", or: "")
		let presences = DiscordPresence.presencesFromArray(guildObject.get("presences", or: [[String: Any]]()), guildId: id)
		let region = guildObject.get("region", or: "")
		let roles = DiscordRole.rolesFromArray(guildObject.get("roles", or: [[String: Any]]()))
		let splash = guildObject.get("splash", or: "")
		let verificationLevel = guildObject.get("verification_level", or: -1)
		let voiceStates = DiscordVoiceState.voiceStatesFromArray(guildObject.get("voice_states", or: [[String: Any]]()),
			guildId: id)
		let unavailable = guildObject.get("unavailable", or: false)
		let joinedAtString = guildObject.get("joined_at", or: "")
		let joinedAt = convertISO8601(string: joinedAtString) ?? Date()

		self.init(features: features, id: id, large: large, joinedAt: joinedAt, splash: splash,
			unavailable: unavailable, defaultMessageNotifications: defaultMessageNotifications,
			embedChannelId: embedChannelId, embedEnabled: embedEnabled, icon: icon, memberCount: memberCount,
			mfaLevel: mfaLevel, name: name, ownerId: ownerId, region: region, verificationLevel: verificationLevel,
			channels: channels, emojis: emojis, members: members, presences: presences, roles: roles,
			voiceStates: voiceStates)
	}

	// Used to setup initial guilds
	static func guildsFromArray(_ guilds: [[String: Any]]) -> [String: DiscordGuild] {
		var guildDictionary = [String: DiscordGuild]()

		for guildObject in guilds {
			let guild = DiscordGuild(guildObject: guildObject)

			guildDictionary[guild.id] = guild
		}

		return guildDictionary
	}
}

public struct DiscordUserGuild {
	public let id: String
	public let name: String
	public let icon: String
	public let owner: Bool
	public let permissions: Int
}

extension DiscordUserGuild {
	init(userGuildObject: [String: Any]) {
		let id = userGuildObject.get("id", or: "")
		let name = userGuildObject.get("name", or: "")
		let icon = userGuildObject.get("icon", or: "")
		let owner = userGuildObject.get("owner", or: false)
		let permissions = userGuildObject.get("permissions", or: 0)

		self.init(id: id, name: name, icon: icon, owner: owner, permissions: permissions)
	}

	static func userGuildsFromArray(_ guilds: [[String: Any]]) -> [String: DiscordUserGuild] {
		var userGuildDictionary = [String: DiscordUserGuild]()

		for guildObject in guilds {
			let guild = DiscordUserGuild(userGuildObject: guildObject)

			userGuildDictionary[guild.id] = guild
		}

		return userGuildDictionary
	}
}
