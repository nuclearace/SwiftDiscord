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

public struct DiscordAttachment {
	public let id: String
	public let filename: String
	public let height: Int?
	public let proxyUrl: URL
	public let size: Int
	public let url: URL
	public let width: Int?
}

extension DiscordAttachment {
	init(attachmentObject: [String: Any]) {
		let id = attachmentObject.get("id", or: "")
		let filename = attachmentObject.get("filename", or: "")
		let height = attachmentObject["height"] as? Int
		let proxyUrl = URL(string: attachmentObject.get("proxy_url", or: "")) ?? URL(string: "http://localhost/")!
		let size = attachmentObject.get("size", or: 0)
		let url = URL(string: attachmentObject.get("url", or: "")) ?? URL(string: "http://localhost/")!
		let width = attachmentObject["width"] as? Int

		self.init(id: id, filename: filename, height: height, proxyUrl: proxyUrl, size: size, url: url, width: width)
	}

	static func attachmentsFromArray(_ attachmentArray: [[String: Any]]) -> [DiscordAttachment] {
		return attachmentArray.map(DiscordAttachment.init)
	}
}

public struct DiscordEmbed {
	public struct Provider {
		public let name: String
		public let url: URL
	}

	public struct Thumbnail {
		public let height: Int
		public let proxyUrl: URL
		public let url: URL
		public let width: Int
	}

	public let description: String
	public let provider: Provider
	public let thumbnail: Thumbnail
	public let title: String
	public let type: String
	public let url: URL
}

extension DiscordEmbed {
	init(embedObject: [String: Any]) {
		let description = embedObject.get("description", or: "")
		let provider = Provider(providerObject: embedObject.get("provider", or: [String: Any]()))
		let thumbnail = Thumbnail(thumbnailObject: embedObject.get("provider", or: [String: Any]()))
		let title = embedObject.get("title", or: "")
		let type = embedObject.get("type", or: "")
		let url = URL(string: embedObject.get("url", or: "")) ?? URL(string: "http://localhost/")!

		self.init(description: description, provider: provider, thumbnail: thumbnail, title: title, type: type,
			url: url)
	}

	static func embedsFromArray(_ embedsArray: [[String: Any]]) -> [DiscordEmbed] {
		return embedsArray.map(DiscordEmbed.init)
	}
}

extension DiscordEmbed.Provider {
	init(providerObject: [String: Any]) {
		let name = providerObject.get("name", or: "")
		let url = URL(string: providerObject.get("url", or: "")) ?? URL(string: "http://localhost/")!

		self.init(name: name, url: url)
	}
}

extension DiscordEmbed.Thumbnail {
	init(thumbnailObject: [String: Any]) {
		let height = thumbnailObject.get("height", or: 0)
		let proxyUrl = URL(string: thumbnailObject.get("proxy_url", or: "")) ?? URL(string: "http://localhost/")!
		let url = URL(string: thumbnailObject.get("url", or: "")) ?? URL(string: "http://localhost/")!
		let width = thumbnailObject.get("width", or: 0)

		self.init(height: height, proxyUrl: proxyUrl, url: url, width: width)
	}
}

public struct DiscordMessage {
	public let attachments: [DiscordAttachment]
	public let author: DiscordUser
	public let channelId: String
	public let content: String
	public let editedTimestamp: Date
	public let embeds: [DiscordEmbed]
	public let id: String
	public let mentionEveryone: Bool
	public let mentionRoles: [String]
	public let mentions: [DiscordUser]
	public let timestamp: Date
	public let tts: Bool
}

extension DiscordMessage {
	init(messageObject: [String: Any]) {
		let attachments = DiscordAttachment.attachmentsFromArray(messageObject.get("attachments", or: [[String: Any]]()))
		let author = DiscordUser(userObject: messageObject.get("author", or: [String: Any]()))
		let channelId = messageObject.get("channel_id", or: "")
		let content = messageObject.get("content", or: "")
		let embeds = DiscordEmbed.embedsFromArray(messageObject.get("embeds", or: [[String: Any]]()))
		let id = messageObject.get("id", or: "")
		let mentionEveryone = messageObject.get("mention_everyone", or: false)
		let mentionRoles = messageObject.get("mention_roles", or: [String]())
		let mentions = DiscordUser.usersFromArray(messageObject.get("mentions", or: [[String: Any]]()))
		let tts = messageObject.get("tts", or: false)
		let editedTimestampString = messageObject.get("edited_timestamp", or: "")
		let editedTimestamp = convertISO8601(string: editedTimestampString) ?? Date()
		let timestampString = messageObject.get("timestamp", or: "")
		let timestamp = convertISO8601(string: timestampString) ?? Date()

		self.init(attachments: attachments, author: author, channelId: channelId, content: content,
			editedTimestamp: editedTimestamp, embeds: embeds, id: id, mentionEveryone: mentionEveryone,
			mentionRoles: mentionRoles, mentions: mentions, timestamp: timestamp, tts: tts)
	}

	static func messagesFromArray(_ array: [[String: Any]]) -> [DiscordMessage] {
		return array.map(DiscordMessage.init)
	}
}
