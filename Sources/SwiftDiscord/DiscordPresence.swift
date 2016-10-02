public struct DiscordGame {
	public let name: String

	public init?(string: String?) {
		guard let string = string else { return nil }

		name = string
	}
}

public enum DiscordPresenceStatus {
	case idle
	case offline
	case online

	public init?(string: String) {
		switch string {
		case "idle":
			self = .idle
		case "offline":
			self = .offline
		case "online":
			self = .online
		default:
			return nil
		}
	}
}

public struct DiscordPresence {
	public let guildId: String
	public let user: DiscordUser

	public var game: DiscordGame?
	public var nick: String
	public var roles: [String]
	public var status: DiscordPresenceStatus
}

extension DiscordPresence {
	init(presenceObject: [String: Any], guildId: String) {
		let user = DiscordUser.userFromDictionary(presenceObject["user"] as? [String: Any] ?? [:])
		let game = DiscordGame(string: presenceObject["game"] as? String)
		let nick = presenceObject["nick"] as? String ?? ""
		let status = DiscordPresenceStatus(string: presenceObject["status"] as? String ?? "") ?? .offline

		self.init(guildId: guildId, user: user, game: game, nick: nick, roles: [], status: status)
	}

	static func presencesFromArray(_ presencesArray: [[String: Any]], guildId: String) -> [String: DiscordPresence] {
		var presences = [String: DiscordPresence]()

		for presence in presencesArray {
			let presence = DiscordPresence(presenceObject: presence, guildId: guildId)

			presences[presence.user.id] = presence
		}

		return presences
	}
}
