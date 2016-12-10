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

/// Represents the type of guild channel.
public enum DiscordChannelType : String {
	/// A text channel.
	case text = "text"

	/// A voice channel
	case voice = "voice"
}

/// Represents a guild channel.
public struct DiscordGuildChannel {
	// MARK: Properties

	/// The snowflake id of the channel.
	public let id: String

	/// Whether this is a private channel. Should always be false for GuildChannels.
	public let isPrivate = false

	/// The snowflake id of the guild this channel is on.
	public let guildId: String

	/// What type of channel this is.
	public let type: DiscordChannelType

	/// The bitrate of this channel, if this is a voice channel.
	public var bitrate: Int?

	/// The last message received on this channel.
	///
	/// **NOTE** Currently is not being updated.
	public var lastMessageId: String?

	/// The name of this channel.
	public var name: String

	/// The permissions specifics to this channel.
	public var permissionOverwrites: [String: DiscordPermissionOverwrite]

	/// The position of this channel. Mostly for UI purpose.
	public var position: Int

	/// The topic of this channel, if this is a text channel.
	public var topic: String?

	/// The user limit of this channel, if this is a voice channel.
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
