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

	init(guildChannelObject: [String: Any]) {
		id = guildChannelObject.get("id", or: "")
		guildId = guildChannelObject.get("guild_id", or: "")
		type = DiscordChannelType(rawValue: guildChannelObject.get("type", or: "")) ?? .text
		bitrate = guildChannelObject.get("bitrate", or: nil) as Int?
		lastMessageId = guildChannelObject.get("last_message_id", or: nil) as String?
		name = guildChannelObject.get("name", or: "")
		permissionOverwrites = DiscordPermissionOverwrite.overwritesFromArray(
			guildChannelObject.get("permission_overwrites", or: [[String: Any]]()))
		position = guildChannelObject.get("position", or: 0)
		topic = guildChannelObject.get("topic", or: nil) as String?
		userLimit = guildChannelObject.get("user_limit", or: nil) as Int?
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
