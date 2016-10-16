public enum DiscordChannelType : String {
	case text = "text"
	case voice = "voice"
}

public struct DiscordGuildChannel {
	public let id: String
	public let isPrivate = false
	public let guildId: String
	public let type: DiscordChannelType

	public var bitrate: Int?
	public var lastMessageId: String?
	public var name: String
	public var permissionOverwrites: [String: DiscordPermissionOverwrite]
	public var position: Int
	public var topic: String?
	public var userLimit: Int?
}

extension DiscordGuildChannel {
	init(guildChannelObject: [String: Any]) {
		let id = guildChannelObject["id"] as? String ?? ""
		let guildId = guildChannelObject["guild_id"] as? String ?? ""
		let type = DiscordChannelType(rawValue: guildChannelObject["type"] as? String ?? "") ?? .text
		let bitrate = guildChannelObject["bitrate"] as? Int
		let lastMessageId = guildChannelObject["last_message_id"] as? String
		let name = guildChannelObject["name"] as? String ?? ""
		let permissionOverwrites = DiscordPermissionOverwrite.overwritesFromArray(
			guildChannelObject["permission_overwrites"] as? [[String: Any]] ?? [])
		let position = guildChannelObject["position"] as? Int ?? -1
		let topic = guildChannelObject["topic"] as? String
		let userLimit = guildChannelObject["user_limit"] as? Int

		self.init(id: id, guildId: guildId, type: type, bitrate: bitrate, lastMessageId: lastMessageId, name: name,
			permissionOverwrites: permissionOverwrites, position: position, topic: topic, userLimit: userLimit)
	}

	static func guildChannelsFromArray(_ guildChannelArray: [[String: Any]]) -> [String: DiscordGuildChannel] {
		var guildChannels = [String: DiscordGuildChannel]()

		for guildChannelObject in guildChannelArray {
			let guildChannel = DiscordGuildChannel(guildChannelObject: guildChannelObject)

			guildChannels[guildChannel.id] = guildChannel
		}

		return guildChannels
	}
}
