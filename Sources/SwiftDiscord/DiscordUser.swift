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

public struct DiscordUser {
	public let avatar: String
	public let bot: Bool
	public let discriminator: String
	public let email: String
	public let id: String
	public let mfaEnabled: Bool
	public let username: String
	public let verified: Bool

	init(userObject: [String: Any]) {
		avatar = userObject.get("avatar", or: "")
		bot = userObject.get("bot", or: false)
		discriminator = userObject.get("discriminator", or: "")
		email = userObject.get("email", or: "")
		id = userObject.get("id", or: "")
		mfaEnabled = userObject.get("mfa_enabled", or: false)
		username = userObject.get("username", or: "")
		verified = userObject.get("verified", or: false)
	}

	static func usersFromArray(_ userArray: [[String: Any]]) -> [DiscordUser] {
		var users = [DiscordUser]()

		for user in userArray {
			users.append(DiscordUser(userObject: user))
		}

		return users
	}
}
