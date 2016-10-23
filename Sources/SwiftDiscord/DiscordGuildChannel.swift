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

public enum DiscordChannelType : String {
	case text = "text"
	case voice = "voice"
}

public struct DiscordGuildChannel {
	public let id: String
	public let isPrivate = false
	public let guildId: String
	public let type: DiscordChannelType

	public var bitrate: Int?
	public var lastMessageId: String?
	public var name: String
	public var permissionOverwrites: [String: DiscordPermissionOverwrite]
	public var position: Int
	public var topic: String?
	public var userLimit: Int?
}

extension DiscordGuildChannel {
	init(guildChannelObject: [String: Any]) {
		let id = guildChannelObject["id"] as? String ?? ""
		let guildId = guildChannelObject["guild_id"] as? String ?? ""
		let type = DiscordChannelType(rawValue: guildChannelObject["type"] as? String ?? "") ?? .text
		let bitrate = guildChannelObject["bitrate"] as? Int
		let lastMessageId = guildChannelObject["last_message_id"] as? String
		let name = guildChannelObject["name"] as? String ?? ""
		let permissionOverwrites = DiscordPermissionOverwrite.overwritesFromArray(
			guildChannelObject["permission_overwrites"] as? [[String: Any]] ?? [])
		let position = guildChannelObject["position"] as? Int ?? -1
		let topic = guildChannelObject["topic"] as? String
		let userLimit = guildChannelObject["user_limit"] as? Int

		self.init(id: id, guildId: guildId, type: type, bitrate: bitrate, lastMessageId: lastMessageId, name: name,
			permissionOverwrites: permissionOverwrites, position: position, topic: topic, userLimit: userLimit)
	}

	static func guildChannelsFromArray(_ guildChannelArray: [[String: Any]]) -> [String: DiscordGuildChannel] {
		var guildChannels = [String: DiscordGuildChannel]()

		for guildChannelObject in guildChannelArray {
			let guildChannel = DiscordGuildChannel(guildChannelObject: guildChannelObject)

			guildChannels[guildChannel.id] = guildChannel
		}

		return guildChannels
	}
}
