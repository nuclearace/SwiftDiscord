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
}

extension DiscordGuild {
	init(guildObject: [String: Any]) {
		let channels = DiscordGuildChannel.guildChannelsFromArray(guildObject["channels"] as? [[String: Any]] ?? [])
		let defaultMessageNotifications = guildObject["default_message_notifications"] as? Int ?? -1
		let embedEnabled = guildObject["embed_enabled"] as? Bool ?? false
		let embedChannelId = guildObject["embed_channel_id"] as? String ?? ""
		let emojis = DiscordEmoji.emojisFromArray(guildObject["emojis"] as? [[String: Any]] ?? [])
		let features = guildObject["features"] as? [Any] ?? []
		let icon = guildObject["icon"] as? String ?? ""
		let id = guildObject["id"] as? String ?? ""
		let large = guildObject["large"] as? Bool ?? false
		let memberCount = guildObject["member_count"] as? Int ?? -1
		let members = DiscordGuildMember.guildMembersFromArray(guildObject["members"] as? [[String: Any]] ?? [])
		let mfaLevel = guildObject["mfa_level"] as? Int ?? -1
		let name = guildObject["name"] as? String ?? ""
		let ownerId = guildObject["owner_id"] as? String ?? ""
		let presences = DiscordPresence.presencesFromArray(guildObject["presences"] as? [[String: Any]] ?? [], guildId: id)
		let region = guildObject["region"] as? String ?? ""
		let roles = DiscordRole.rolesFromArray(guildObject["roles"] as? [[String: Any]] ?? [])
		let splash = guildObject["splash"] as? String ?? ""
		let verificationLevel = guildObject["verification_level"] as? Int ?? -1
		let voiceStates = DiscordVoiceState.voiceStatesFromArray(guildObject["voice_states"] as? [[String: Any]] ?? [],
			guildId: id)
		let unavailable = guildObject["unavailable"] as? Bool ?? false

		let joinedAtString = guildObject["joined_at"] as? String ?? ""
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
		let id = userGuildObject["id"] as? String ?? ""
		let name = userGuildObject["name"] as? String ?? ""
		let icon = userGuildObject["icon"] as? String ?? ""
		let owner = userGuildObject["owner"] as? Bool ?? false
		let permissions = userGuildObject["permissions"] as? Int ?? 0

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
