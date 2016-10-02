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
	static func userFromDictionary(_ user: [String: Any]) -> DiscordUser {
		let avatar = user["avatar"] as? String ?? ""
		let bot = user["bot"] as? Bool ?? false
		let discriminator = user["discriminator"] as? String ?? ""
		let email = user["email"] as? String ?? ""
		let id = user["id"] as? String ?? ""
		let mfaEnabled = user["mfa_enabled"] as? Bool ?? false
		let username = user["username"] as? String ?? ""
		let verified = user["verified"] as? Bool ?? false

		return DiscordUser(avatar: avatar, bot: bot, discriminator: discriminator, email: email, id: id,
				mfaEnabled: mfaEnabled, username: username, verified: verified)
	}
}
