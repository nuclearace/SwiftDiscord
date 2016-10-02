import Foundation

public struct DiscordGuildMember {
	public let user: DiscordUser
	public let joinedAt: Date

	public var deaf: Bool
	public var mute: Bool
	public var nick: String?
	public var roles: [String]
}

extension DiscordGuildMember {
	init(guildMemberObject: [String: Any]) {
		let user = DiscordUser(userObject: guildMemberObject["user"] as? [String: Any] ?? [:])
		let deaf = guildMemberObject["deaf"] as? Bool ?? false
		let mute = guildMemberObject["mute"] as? Bool ?? false
		let nick = guildMemberObject["nick"] as? String
		let roles = guildMemberObject["roles"] as? [String] ?? []

		let joinedAtString = guildMemberObject["joined_at"] as? String ?? ""
		let joinedAt = convertISO8601(string: joinedAtString) ?? Date()

		self.init(user: user, joinedAt: joinedAt, deaf: deaf, mute: mute, nick: nick, roles: roles)
	}

	static func guildMembersFromArray(_ guildMembersArray: [[String: Any]]) -> [String: DiscordGuildMember] {
		var guildMembers = [String: DiscordGuildMember]()

		for guildMember in guildMembersArray {
			let guildMember = DiscordGuildMember(guildMemberObject: guildMember)

			guildMembers[guildMember.user.id] = guildMember
		}

		return guildMembers
	}
}
