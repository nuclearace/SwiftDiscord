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
		let user = DiscordUser(userObject: guildMemberObject.get("user", or: [String: Any]()))
		let deaf = guildMemberObject.get("deaf", or: false)
		let mute = guildMemberObject.get("mute", or: false)
		let nick = guildMemberObject.get("nick", or: nil) as String?
		let roles = guildMemberObject.get("roles", or: [String]())
		let joinedAtString = guildMemberObject.get("joined_at", or: "")
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
