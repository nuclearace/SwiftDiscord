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

/// Declares that a type will act as a Discord user.
public protocol DiscordUserActor {
	// MARK: Properties

	/// The guilds that this user is in.
	var guilds: [String: DiscordGuild] { get }

	/// The relationships this user has. Only valid for non-bot users.
	var relationships: [[String: Any]] { get }

	/// The Discord JWT for the user.
	var token: DiscordToken { get }

	/// The DiscordUser.
	var user: DiscordUser? { get }

	/// The voice state for this user, if they are in a voice channel.
	var voiceState: DiscordVoiceState? { get }
}

/// Represents a Discord user.
public struct DiscordUser {
	// MARK: Properties

	/// The base64 encoded avatar of this user.
	public let avatar: String

	/// Whether this user is a bot.
	public let bot: Bool

	/// This user's discriminator.
	public let discriminator: String

	/// The user's email. Only availabe if we are the user.
	public let email: String

	/// The snowflake id of the user.
	public let id: String

	/// Whether this user has multi-factor authentication enabled.
	public let mfaEnabled: Bool

	/// This user's username.
	public let username: String

	/// Whether this user is verified.
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
