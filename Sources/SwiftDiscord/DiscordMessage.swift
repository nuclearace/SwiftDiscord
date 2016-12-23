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

/// Represents an attachment.
public struct DiscordAttachment {
	// MARK: Properties

	/// The snowflake id of this attachment.
	public let id: String

	/// The name of the file.
	public let filename: String

	/// The height, if this is an image.
	public let height: Int?

	/// The proxy url for this attachment.
	public let proxyUrl: URL

	/// The size of this attachment.
	public let size: Int

	/// The url of this attachment.
	public let url: URL

	/// The width, if this is an image.
	public let width: Int?

	init(attachmentObject: [String: Any]) {
		id = attachmentObject.get("id", or: "")
		filename = attachmentObject.get("filename", or: "")
		height = attachmentObject["height"] as? Int
		proxyUrl = URL(string: attachmentObject.get("proxy_url", or: "")) ?? URL(string: "http://localhost/")!
		size = attachmentObject.get("size", or: 0)
		url = URL(string: attachmentObject.get("url", or: "")) ?? URL(string: "http://localhost/")!
		width = attachmentObject["width"] as? Int
	}

	static func attachmentsFromArray(_ attachmentArray: [[String: Any]]) -> [DiscordAttachment] {
		return attachmentArray.map(DiscordAttachment.init)
	}
}

/// Represents an embeded entity.
public struct DiscordEmbed {
	// MARK: Nested Types

	/// Represents what is providing the content of an embed.
	public struct Provider {
		// MARK: Properties

		/// The name of this provider.
		public let name: String

		/// The url of this provider.
		public let url: URL
	}

	/// Represents the thumbnail of an embed.
	public struct Thumbnail {
		// MARK: Properties

		/// The height of this image.
		public let height: Int

		/// The proxy url for this image.
		public let proxyUrl: URL

		/// The url for this image.
		public let url: URL

		/// The width of this image.
		public let width: Int
	}

	// MARK: Properties

	/// The description of this embed.
	public let description: String

	/// The provider of this embed.
	public let provider: Provider

	/// The thumbnail of this embed.
	public let thumbnail: Thumbnail

	/// The title of this embed.
	public let title: String

	/// The type of this embed.
	public let type: String

	/// The url of this embed.
	public let url: URL

	init(embedObject: [String: Any]) {
		description = embedObject.get("description", or: "")
		provider = Provider(providerObject: embedObject.get("provider", or: [String: Any]()))
		thumbnail = Thumbnail(thumbnailObject: embedObject.get("provider", or: [String: Any]()))
		title = embedObject.get("title", or: "")
		type = embedObject.get("type", or: "")
		url = URL(string: embedObject.get("url", or: "")) ?? URL(string: "http://localhost/")!
	}

	static func embedsFromArray(_ embedsArray: [[String: Any]]) -> [DiscordEmbed] {
		return embedsArray.map(DiscordEmbed.init)
	}
}

extension DiscordEmbed.Provider {
	init(providerObject: [String: Any]) {
		name = providerObject.get("name", or: "")
		url = URL(string: providerObject.get("url", or: "")) ?? URL(string: "http://localhost/")!
	}
}

extension DiscordEmbed.Thumbnail {
	init(thumbnailObject: [String: Any]) {
		height = thumbnailObject.get("height", or: 0)
		proxyUrl = URL(string: thumbnailObject.get("proxy_url", or: "")) ?? URL(string: "http://localhost/")!
		url = URL(string: thumbnailObject.get("url", or: "")) ?? URL(string: "http://localhost/")!
		width = thumbnailObject.get("width", or: 0)
	}
}

/// Represents a message reaction.
public struct DiscordReaction {
	// MARK: Properties

	/// The number of times this emoji has been used to react.
	public let count: Int

	/// Whether the current user reacted with this emoji.
	public let me: Bool

	/// The emoji used to react.
	public let emoji: DiscordEmoji

	init(reactionObject: [String: Any]) {
		count = reactionObject.get("count", or: -1)
		me = reactionObject.get("me", or: false)
		emoji = DiscordEmoji(emojiObject: reactionObject.get("emoji", or: [:]))
	}

	static func reactionsFromArray(_ reactionsArray: [[String: Any]]) -> [DiscordReaction] {
		return reactionsArray.map(DiscordReaction.init)
	}
}

/// Represents a Discord chat message.
public struct DiscordMessage : DiscordClientHolder {
	// MARK: Properties

	/// The attachments included in this message.
	public let attachments: [DiscordAttachment]

	/// Who sent this message.
	public let author: DiscordUser

	/// The snowflake id of the channel this message is on.
	public let channelId: String

	/// A reference to the client.
	public weak var client: DiscordClient?

	/// The content of this message.
	public let content: String

	/// When this message was last edited.
	public let editedTimestamp: Date

	/// The embeds that are in this message.
	public let embeds: [DiscordEmbed]

	/// The snowflake id of this message.
	public let id: String

	/// Whether or not this message mentioned everyone.
	public let mentionEveryone: Bool

	/// List of snowflake ids of roles that were mentioned in this message.
	public let mentionRoles: [String]

	/// List of users that were mentioned in this message.
	public let mentions: [DiscordUser]

	/// Used for validating a message was sent.
	public let nonce: String

	/// Whether this message is pinned.
	public let pinned: Bool

	/// The reactions a message has.
	public let reactions: [DiscordReaction]

	/// The timestamp of this message.
	public let timestamp: Date

	/// Whether or not this message should be read by a screen reader.
	public let tts: Bool

	/// The channel that this message originated from. Can return nil if the channel couldn't be found.
	public var channel: DiscordChannel? {
		return client?.findChannel(fromId: channelId)
	}

	init(messageObject: [String: Any], client: DiscordClient?) {
		attachments = DiscordAttachment.attachmentsFromArray(messageObject.get("attachments", or: [[String: Any]]()))
		author = DiscordUser(userObject: messageObject.get("author", or: [String: Any]()))
		channelId = messageObject.get("channel_id", or: "")
		content = messageObject.get("content", or: "")
		embeds = DiscordEmbed.embedsFromArray(messageObject.get("embeds", or: [[String: Any]]()))
		id = messageObject.get("id", or: "")
		mentionEveryone = messageObject.get("mention_everyone", or: false)
		mentionRoles = messageObject.get("mention_roles", or: [String]())
		mentions = DiscordUser.usersFromArray(messageObject.get("mentions", or: [[String: Any]]()))
		nonce = messageObject.get("nonce", or: "")
		pinned = messageObject.get("pinned", or: false)
		reactions = DiscordReaction.reactionsFromArray(messageObject.get("reactions", or: []))
		tts = messageObject.get("tts", or: false)
		editedTimestamp = convertISO8601(string: messageObject.get("edited_timestamp", or: "")) ?? Date()
		timestamp = convertISO8601(string: messageObject.get("timestamp", or: "")) ?? Date()
		self.client = client
	}

	// MARK: Methods

	/**
		Deletes this message from Discord.
	*/
	public func delete() {
		channel?.deleteMessage(self)
	}

	static func messagesFromArray(_ array: [[String: Any]]) -> [DiscordMessage] {
		return array.map({ DiscordMessage(messageObject: $0, client: nil) })
	}
}
