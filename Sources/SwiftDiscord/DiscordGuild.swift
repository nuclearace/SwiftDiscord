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

	public internal(set) var channels: [String: DiscordGuildChannel]
	public internal(set) var emojis: [String: DiscordEmoji]
	public internal(set) var memberCount: Int
	public internal(set) var members: DiscordLazyDictionary<String, DiscordGuildMember>
	public internal(set) var presences: DiscordLazyDictionary<String, DiscordPresence>
	public internal(set) var roles: [String: DiscordRole]
	public internal(set) var voiceStates: [String: DiscordVoiceState]

	public private(set) var defaultMessageNotifications: Int
	public private(set) var embedChannelId: String
	public private(set) var embedEnabled: Bool
	public private(set) var icon: String
	public private(set) var mfaLevel: Int
	public private(set) var name: String
	public private(set) var ownerId: String
	public private(set) var region: String
	public private(set) var verificationLevel: Int

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

	init(guildObject: [String: Any]) {
		channels = DiscordGuildChannel.guildChannelsFromArray(guildObject.get("channels", or: [[String: Any]]()))
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

	init(userGuildObject: [String: Any]) {
		id = userGuildObject.get("id", or: "")
		name = userGuildObject.get("name", or: "")
		icon = userGuildObject.get("icon", or: "")
		owner = userGuildObject.get("owner", or: false)
		permissions = userGuildObject.get("permissions", or: 0)
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
