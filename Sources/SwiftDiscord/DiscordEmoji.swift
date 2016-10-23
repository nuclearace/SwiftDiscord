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

public struct DiscordEmoji {
	public let id: String
	public let managed: Bool
	public let name: String
	public let requireColons: Bool
	public let roles: [String]
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
