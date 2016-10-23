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
		let id = attachmentObject["id"] as? String ?? ""
		let filename = attachmentObject["filename"] as? String ?? ""
		let height = attachmentObject["height"] as? Int
		let proxyUrl = URL(string: attachmentObject["proxy_url"] as? String ?? "") ?? URL(string: "http://localhost/")!
		let size = attachmentObject["size"] as? Int ?? -1
		let url = URL(string: attachmentObject["url"] as? String ?? "") ?? URL(string: "http://localhost/")!
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
		let description = embedObject["description"] as? String ?? ""
		let provider = Provider(providerObject: embedObject["provider"] as? [String: Any] ?? [:])
		let thumbnail = Thumbnail(thumbnailObject: embedObject["provider"] as? [String: Any] ?? [:])
		let title = embedObject["title"] as? String ?? ""
		let type = embedObject["type"] as? String ?? ""
		let url = URL(string: embedObject["url"] as? String ?? "") ?? URL(string: "http://localhost/")!

		self.init(description: description, provider: provider, thumbnail: thumbnail, title: title, type: type,
			url: url)
	}

	static func embedsFromArray(_ embedsArray: [[String: Any]]) -> [DiscordEmbed] {
		return embedsArray.map(DiscordEmbed.init)
	}
}

extension DiscordEmbed.Provider {
	init(providerObject: [String: Any]) {
		let name = providerObject["name"] as? String ?? ""
		let url = URL(string: providerObject["url"] as? String ?? "") ?? URL(string: "http://localhost/")!

		self.init(name: name, url: url)
	}
}

extension DiscordEmbed.Thumbnail {
	init(thumbnailObject: [String: Any]) {
		let height = thumbnailObject["height"] as? Int ?? -1
		let proxyUrl = URL(string: thumbnailObject["proxy_url"] as? String ?? "") ?? URL(string: "http://localhost/")!
		let url = URL(string: thumbnailObject["url"] as? String ?? "") ?? URL(string: "http://localhost/")!
		let width = thumbnailObject["width"] as? Int ?? -1

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
		let attachments = DiscordAttachment.attachmentsFromArray(
			messageObject["attachments"] as? [[String: Any]] ?? [])
		let author = DiscordUser(userObject: messageObject["author"] as? [String: Any] ?? [:])
		let channelId = messageObject["channel_id"] as? String ?? ""
		let content = messageObject["content"] as? String ?? ""
		let embeds = DiscordEmbed.embedsFromArray(messageObject["embeds"] as? [[String: Any]] ?? [])
		let id = messageObject["id"] as? String ?? ""
		let mentionEveryone = messageObject["mention_everyone"] as? Bool ?? false
		let mentionRoles = messageObject["mention_roles"] as? [String] ?? []
		let mentions = DiscordUser.usersFromArray(messageObject["mentions"] as? [[String: Any]] ?? [])
		let tts = messageObject["tts"] as? Bool ?? false

		let editedTimestampString = messageObject["edited_timestamp"] as? String ?? ""
		let editedTimestamp = convertISO8601(string: editedTimestampString) ?? Date()

		let timestampString = messageObject["timestamp"] as? String ?? ""
		let timestamp = convertISO8601(string: timestampString) ?? Date()

		self.init(attachments: attachments, author: author, channelId: channelId, content: content,
			editedTimestamp: editedTimestamp, embeds: embeds, id: id, mentionEveryone: mentionEveryone,
			mentionRoles: mentionRoles, mentions: mentions, timestamp: timestamp, tts: tts)
	}

	static func messagesFromArray(_ array: [[String: Any]]) -> [DiscordMessage] {
		return array.map(DiscordMessage.init)
	}
}
