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

public enum DiscordGameType {
	case game
	case stream(String)

	init(int: Int, url: String?) {
		if int == 0 {
			self = .game
		} else if int == 1 && url != nil {
			self = .stream(url!)
		} else {
			self = .game
		}
	}
}

public struct DiscordGame {
	public let name: String
	public let type: DiscordGameType

	public init?(gameObject: [String: Any]?) {
		guard let game = gameObject else { return nil }
		guard let name = game["name"] as? String else { return nil }

		self.name = name
		self.type = DiscordGameType(int: game.get("type", or: 0), url: game["url"] as? String)
	}
}

public enum DiscordPresenceStatus : String {
	case idle = "idle"
	case offline = "offline"
	case online = "online"
}

public struct DiscordPresence {
	public let guildId: String
	public let user: DiscordUser

	public var game: DiscordGame?
	public var nick: String
	public var roles: [String]
	public var status: DiscordPresenceStatus

	init(presenceObject: [String: Any], guildId: String) {
		self.guildId = guildId
		user = DiscordUser(userObject: presenceObject.get("user", or: [String: Any]()))
		game = DiscordGame(gameObject: presenceObject["game"] as? [String: Any])
		nick = presenceObject.get("nick", or: "")
		status = DiscordPresenceStatus(rawValue: presenceObject.get("status", or: "")) ?? .offline
		roles = []
	}

	mutating func updatePresence(presenceObject: [String: Any]) {
		if let game = presenceObject["game"] as? [String: Any] {
			self.game = DiscordGame(gameObject: game)
		} else {
			game = nil
		}

		if let nick = presenceObject["nick"] as? String {
			self.nick = nick
		}

		if let roles = presenceObject["roles"] as? [String] {
			self.roles = roles
		}

		if let status = presenceObject["status"] as? String {
			self.status = DiscordPresenceStatus(rawValue: status) ?? .offline
		}
	}

	static func presencesFromArray(_ presencesArray: [[String: Any]], guildId: String)
			-> DiscordLazyDictionary<String, DiscordPresence> {
		var presences = DiscordLazyDictionary<String, DiscordPresence>()

		for presence in presencesArray {
			guard let user = presence["user"] as? [String: Any], let id = user["id"] as? String else {
				fatalError("Couldn't extract userId")
			}

			presences[lazy: id] = .lazy({ DiscordPresence(presenceObject: presence, guildId: guildId) })
		}

		return presences
	}
}
