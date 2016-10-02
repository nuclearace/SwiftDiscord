import Foundation

public struct DiscordGuild {
	public let defaultMessageNotifications: Int
	public let embedChannelId: String
	public let embedEnabled: Bool
	public let features: [Any] // TODO figure out what features are
	public let icon: String
	public let id: String
	public let joinedAt: Date
	public let large: Bool
	public let mfaLevel: Int
	public let ownerId: String
	public let region: String
	public let splash: String
	public let unavailable: Bool
	public let verificationLevel: Int

	public var channels: [String: DiscordGuildChannel]
	public var emojis: [String: DiscordEmoji]
	public var memberCount: Int
	public var members: [String: DiscordGuildMember]
	public var name: String
	public var roles: [String: DiscordRole]
	public var voiceStates: [String: DiscordVoiceState]
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
		let region = guildObject["region"] as? String ?? ""
		let roles = DiscordRole.rolesFromArray(guildObject["roles"] as? [[String: Any]] ?? [])
		let splash = guildObject["splash"] as? String ?? ""
		let verificationLevel = guildObject["verification_level"] as? Int ?? -1
		let voiceStates = DiscordVoiceState.voiceStatesFromArray(guildObject["voice_states"] as? [[String: Any]] ?? [],
			guildId: id)
		let unavailable = guildObject["unavailable"] as? Bool ?? false
		
		let joinedAtString = guildObject["joined_at"] as? String ?? ""
		let joinedAt = convertISO8601(string: joinedAtString) ?? Date()

		self.init(defaultMessageNotifications: defaultMessageNotifications, embedChannelId: embedChannelId, 
			embedEnabled: embedEnabled, features: features, icon: icon, id: id, joinedAt: joinedAt,large: large, 
			mfaLevel: mfaLevel, ownerId: ownerId, region: region, splash: splash, unavailable: unavailable, 
			verificationLevel: verificationLevel, channels: channels, emojis: emojis, memberCount: memberCount, 
			members: members, name: name, roles: roles, voiceStates: voiceStates)
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
