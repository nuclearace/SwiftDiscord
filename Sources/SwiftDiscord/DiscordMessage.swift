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

	init(messageObject: [String: Any]) {
		attachments = DiscordAttachment.attachmentsFromArray(messageObject.get("attachments", or: [[String: Any]]()))
		author = DiscordUser(userObject: messageObject.get("author", or: [String: Any]()))
		channelId = messageObject.get("channel_id", or: "")
		content = messageObject.get("content", or: "")
		embeds = DiscordEmbed.embedsFromArray(messageObject.get("embeds", or: [[String: Any]]()))
		id = messageObject.get("id", or: "")
		mentionEveryone = messageObject.get("mention_everyone", or: false)
		mentionRoles = messageObject.get("mention_roles", or: [String]())
		mentions = DiscordUser.usersFromArray(messageObject.get("mentions", or: [[String: Any]]()))
		tts = messageObject.get("tts", or: false)
		editedTimestamp = convertISO8601(string: messageObject.get("edited_timestamp", or: "")) ?? Date()
		timestamp = convertISO8601(string: messageObject.get("timestamp", or: "")) ?? Date()
	}

	static func messagesFromArray(_ array: [[String: Any]]) -> [DiscordMessage] {
		return array.map(DiscordMessage.init)
	}
}
