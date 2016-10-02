public struct DiscordEmoji {
	let id: String
	let managed: Bool
	let name: String
	let requireColons: Bool
	let roles: [String]
}

extension DiscordEmoji {
	init(emojiObject: [String: Any]) {
		let id = emojiObject["id"] as? String ?? ""
		let managed = emojiObject["managed"] as? Bool ?? false
		let name = emojiObject["name"] as? String ?? ""
		let requireColons = emojiObject["require_colons"] as? Bool ?? false
		let roles = emojiObject["roles"] as? [String] ?? []

		self.init(id: id, managed: managed, name: name, requireColons: requireColons, roles: roles)
	}

	static func emojisFromArray(_ emojiArray: [[String: Any]]) -> [String: DiscordEmoji] {
		var emojis = [String: DiscordEmoji]()

		for emoji in emojiArray {
			let emoji = DiscordEmoji(emojiObject: emoji)

			emojis[emoji.id] = emoji
		}

		return emojis
	}
}
