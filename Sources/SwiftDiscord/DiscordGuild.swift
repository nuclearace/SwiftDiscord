import Foundation

// TODO figure out which fields are mutable
public struct DiscordGuild {
	let defaultMessageNotifications: Int
	let embedChannelId: String
	let embedEnabled: Bool
	let emojis: [String: DiscordEmoji]
	let features: [Any] // TODO figure out what features are
	let icon: String
	let id: String
	let joinedAt: Date
	let large: Bool
	let mfaLevel: Int
	let name: String
	let ownerId: String
	let region: String
	let roles: [String: DiscordRole]
	let splash: String
	let unavailable: Bool
	let verificationLevel: Int
}

extension DiscordGuild {
	init(guildObject: [String: Any]) {
		let defaultMessageNotifications = guildObject["default_message_notifications"] as? Int ?? -1
		let embedEnabled = guildObject["embed_enabled"] as? Bool ?? false
		let embedChannelId = guildObject["embed_channel_id"] as? String ?? ""
		let emojis = DiscordEmoji.emojisFromArray(guildObject["emojis"] as? [[String: Any]] ?? [])
		let features = guildObject["features"] as? [Any] ?? []
		let icon = guildObject["icon"] as? String ?? ""
		let id = guildObject["id"] as? String ?? ""
		let large = guildObject["large"] as? Bool ?? false
		let mfaLevel = guildObject["mfa_level"] as? Int ?? -1
		let name = guildObject["name"] as? String ?? ""
		let ownerId = guildObject["owner_id"] as? String ?? ""
		let region = guildObject["region"] as? String ?? ""
		let roles = DiscordRole.rolesFromArray(guildObject["roles"] as? [[String: Any]] ?? [])
		let splash = guildObject["splash"] as? String ?? ""
		let verificationLevel = guildObject["verification_level"] as? Int ?? -1
		let unavailable = guildObject["unavailable"] as? Bool ?? false
		
		let joinedAtString = guildObject["joined_at"] as? String ?? ""
		let joinedAt = convertISO8601(string: joinedAtString) ?? Date()

		self.init(defaultMessageNotifications: defaultMessageNotifications, embedChannelId: embedChannelId, 
			embedEnabled: embedEnabled, emojis: emojis, features: features, icon: icon, id: id, joinedAt: joinedAt,
			large: large, mfaLevel: mfaLevel, name: name, ownerId: ownerId, region: region, roles: roles, 
			splash: splash, unavailable: unavailable, verificationLevel: verificationLevel)
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
