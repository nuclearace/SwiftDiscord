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
		let user = DiscordUser(userObject: presenceObject["user"] as? [String: Any] ?? [:])
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
