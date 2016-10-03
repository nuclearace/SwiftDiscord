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
		print("update guild")

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
