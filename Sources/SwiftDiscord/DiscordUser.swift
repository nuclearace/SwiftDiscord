import Foundation

public struct DiscordUser {
	public let avatar: String
	public let bot: Bool
	public let discriminator: String
	public let email: String
	public let id: String
	public let mfaEnabled: Bool
	public let username: String
	public let verified: Bool
}

extension DiscordUser {
	init(userObject: [String: Any]) {
		let avatar = userObject["avatar"] as? String ?? ""
		let bot = userObject["bot"] as? Bool ?? false
		let discriminator = userObject["discriminator"] as? String ?? ""
		let email = userObject["email"] as? String ?? ""
		let id = userObject["id"] as? String ?? ""
		let mfaEnabled = userObject["mfa_enabled"] as? Bool ?? false
		let username = userObject["username"] as? String ?? ""
		let verified = userObject["verified"] as? Bool ?? false

		self.init(avatar: avatar, bot: bot, discriminator: discriminator, email: email, id: id,
				mfaEnabled: mfaEnabled, username: username, verified: verified)
	}

	static func usersFromArray(_ userArray: [[String: Any]]) -> [DiscordUser] {
		var users = [DiscordUser]()

		for user in userArray {
			users.append(DiscordUser(userObject: user))
		}

		return users
	}
}
