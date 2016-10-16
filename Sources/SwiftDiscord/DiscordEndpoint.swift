import Foundation

public struct DiscordEndpointOptions {
	private init() {}

	/**
		after, around and before are mutually exclusive.
		They shouldn't be in the same get request
	*/
	public enum GetMessage {
		case after(DiscordMessage)
		case around(DiscordMessage)
		case before(DiscordMessage)
		case limit(Int)
	}

	public enum ModifyChannel {
		case bitrate(Int)
		case name(String)
		case position(Int)
		case topic(String)
		case userLimit(Int)
	}

	public enum CreateInvite {
		case maxAge(Int)
		case maxUses(Int)
		case temporary(Int)
		case unique(Bool)
	}
}

// TODO Group DM
// Guilds

public enum DiscordEndpoint : String {
	case baseURL = "https://discordapp.com/api"
	case channel = "/channels/channel.id"

	// Messages
	case messages = "/channels/channel.id/messages"
	case bulkMessageDelete = "/channels/channel.id/messages/bulk_delete"
	case channelMessage = "/channels/channel.id/messages/message.id"
	case typing = "/channels/channel.id/typing"

	// Permissions
	case permissions = "/channels/channel.id/permissions"
	case channelPermission = "/channels/channel.id/permissions/overwrite.id"

	// Invites
	case invites = "/invites/invite.code"
	case channelInvites = "/channels/channel.id/invites"

	// Pinned Messages
	case pins = "/channels/channel.id/pins"
	case pinnedMessage = "/channels/channel.id/pins/message.id"

	var combined: String {
		return DiscordEndpoint.baseURL.rawValue + rawValue
	}

	private static func createRequest(with token: String, for endpoint: DiscordEndpoint,
		replacing: [String: String], isBot bot: Bool, getParams: [String: String]? = nil) -> URLRequest {

		var request = URLRequest(url: endpoint.createURL(replacing: replacing, getParams: getParams ?? [:]))

		let tokenValue: String

		if bot {
			tokenValue = "Bot \(token)"
		} else {
			tokenValue = token
		}

		request.setValue(tokenValue, forHTTPHeaderField: "Authorization")

		return request
	}

	private func createURL(replacing: [String: String], getParams: [String: String]) -> URL {
		var combined = self.combined

		for (key, value) in replacing {
			combined = combined.replacingOccurrences(of: key, with: value)
		}

		var com = URLComponents(url: URL(string: combined)!, resolvingAgainstBaseURL: false)!

		com.queryItems = getParams.map({ URLQueryItem(name: $0.key, value: $0.value) })

		return com.url!
	}

	public static func getChannel(_ channelId: String, with token: String, isBot bot: Bool,
			callback: @escaping (DiscordGuildChannel?) -> Void) {
		var request = createRequest(with: token, for: .channel, replacing: ["channel.id": channelId], isBot: bot)

		request.httpMethod = "GET"

		let rateLimiterKey = DiscordRateLimitKey(endpoint: .channel, parameters: ["channel.id": channelId])

		DiscordRateLimiter.executeRequest(request, for: rateLimiterKey, callback: {data, response, error in
			guard let data = data, response?.statusCode == 200 else {
				callback(nil)

				return
			}

			guard let stringData = String(data: data, encoding: .utf8), let json = decodeJSON(stringData),
				case let .dictionary(channel) = json else {
					callback(nil)

					return
			}

			callback(DiscordGuildChannel(guildChannelObject: channel))
		})
	}

	public static func deleteChannel(_ channelId: String, with token: String, isBot bot: Bool) {
		var request = createRequest(with: token, for: .channel, replacing: [
			"channel.id": channelId,
			], isBot: bot)

		request.httpMethod = "DELETE"

		let rateLimiterKey = DiscordRateLimitKey(endpoint: .channel, parameters: ["channel.id": channelId])

		DiscordRateLimiter.executeRequest(request, for: rateLimiterKey, callback: {data, response, error in })
	}

	// Messages
	public static func bulkDeleteMessages(_ messages: [String], on channelId: String, with token: String,
			isBot bot: Bool) {
		var request = createRequest(with: token, for: .bulkMessageDelete, replacing: [
			"channel.id": channelId
			], isBot: bot)

		let editObject = [
			"messages": messages
		]

		guard let contentData = encodeJSON(editObject)?.data(using: .utf8, allowLossyConversion: false) else {
			return
		}

		request.httpMethod = "POST"
		request.httpBody = contentData
		request.setValue("application/json", forHTTPHeaderField: "Content-Type")
		request.setValue(String(contentData.count), forHTTPHeaderField: "Content-Length")

		let rateLimiterKey = DiscordRateLimitKey(endpoint: .messages, parameters: ["channel.id": channelId])

		DiscordRateLimiter.executeRequest(request, for: rateLimiterKey, callback: {data, response, error in })
	}

	public static func deleteMessage(_ messageId: String, on channelId: String, with token: String, isBot bot: Bool) {
		var request = createRequest(with: token, for: .channelMessage, replacing: [
			"channel.id": channelId,
			"message.id": messageId
			], isBot: bot)

		request.httpMethod = "DELETE"

		let rateLimiterKey = DiscordRateLimitKey(endpoint: .messages, parameters: ["channel.id": channelId])

		DiscordRateLimiter.executeRequest(request, for: rateLimiterKey, callback: {data, response, error in })
	}

	public static func editMessage(_ messageId: String, on channelId: String, content: String, with token: String,
			isBot bot: Bool) {
		var request = createRequest(with: token, for: .channelMessage, replacing: [
			"channel.id": channelId,
			"message.id": messageId
			], isBot: bot)

		let editObject = [
			"content": content
		]

		guard let contentData = encodeJSON(editObject)?.data(using: .utf8, allowLossyConversion: false) else {
			return
		}

		request.httpMethod = "PATCH"
		request.httpBody = contentData
		request.setValue("application/json", forHTTPHeaderField: "Content-Type")
		request.setValue(String(contentData.count), forHTTPHeaderField: "Content-Length")

		let rateLimiterKey = DiscordRateLimitKey(endpoint: .messages, parameters: ["channel.id": channelId])

		DiscordRateLimiter.executeRequest(request, for: rateLimiterKey, callback: {data, response, error in })
	}

	public static func getMessages(for channel: String, with token: String,
			options: [DiscordEndpointOptions.GetMessage], isBot bot: Bool,
			callback: @escaping ([DiscordMessage]) -> Void) {
		var getParams: [String: String] = [:]

		for option in options {
			switch option {
			case let .after(message):
				getParams["after"] = String(message.id)
			case let .around(message):
				getParams["around"] = String(message.id)
			case let .before(message):
				getParams["before"] = String(message.id)
			case let .limit(number):
				getParams["limit"] = String(number)
			}
		}

		var request = createRequest(with: token, for: .messages, replacing: ["channel.id": channel], isBot: bot,
			getParams: getParams)

		request.httpMethod = "GET"

		let rateLimiterKey = DiscordRateLimitKey(endpoint: .messages, parameters: ["channel.id": channel])

		DiscordRateLimiter.executeRequest(request, for: rateLimiterKey, callback: {data, response, error in
			guard let data = data, response?.statusCode == 200 else {
				callback([])

				return
			}

			guard let stringData = String(data: data, encoding: .utf8), let json = decodeJSON(stringData),
				case let .array(messages) = json else {
					callback([])

					return
			}

			callback(DiscordMessage.messagesFromArray(messages as! [[String: Any]]))
		})
	}

	public static func sendMessage(_ content: String, with token: String, to channel: String, tts: Bool,
			isBot bot: Bool) {
		let messageObject: [String: Any] = [
			"content": content,
			"tts": tts
		]

		guard let contentData = encodeJSON(messageObject)?.data(using: .utf8, allowLossyConversion: false) else {
			return
		}

		var request = createRequest(with: token, for: .messages, replacing: ["channel.id": channel], isBot: bot)

		request.httpMethod = "POST"
		request.httpBody = contentData
		request.setValue("application/json", forHTTPHeaderField: "Content-Type")
		request.setValue(String(contentData.count), forHTTPHeaderField: "Content-Length")

		let rateLimiterKey = DiscordRateLimitKey(endpoint: .messages, parameters: ["channel.id": channel])

        DiscordRateLimiter.executeRequest(request, for: rateLimiterKey, callback: {data, response, error in })
	}

	public static func triggerTyping(on channelId: String, with token: String, isBot bot: Bool) {
		var request = createRequest(with: token, for: .typing, replacing: ["channel.id": channelId], isBot: bot)

		request.httpMethod = "POST"

		let rateLimiterKey = DiscordRateLimitKey(endpoint: .typing, parameters: ["channel.id": channelId])

		DiscordRateLimiter.executeRequest(request, for: rateLimiterKey, callback: {data, response, error in })
	}

	public static func uploadFile() {

	}

	// Permissions
	public static func deleteChannelPermission(_ overwriteId: String, on channelId: String, with token: String,
			isBot bot: Bool) {
		var request = createRequest(with: token, for: .channelPermission, replacing: [
			"channel.id": channelId,
			"overwrite.id": overwriteId
			], isBot: bot)

		request.httpMethod = "DELETE"

		let rateLimiterKey = DiscordRateLimitKey(endpoint: .permissions, parameters: ["channel.id": channelId])

		DiscordRateLimiter.executeRequest(request, for: rateLimiterKey, callback: {data, response, error in })
	}

	public static func editChannelPermission(_ permissionOverwrite: DiscordPermissionOverwrite, on channelId: String,
			with token: String, isBot bot: Bool) {
		let overwriteJSON: [String: Any] = [
			"allow": permissionOverwrite.allow,
			"deny": permissionOverwrite.deny,
			"type": permissionOverwrite.type.rawValue
		]

		guard let contentData = encodeJSON(overwriteJSON)?.data(using: .utf8, allowLossyConversion: false) else {
			return
		}

		var request = createRequest(with: token, for: .channelPermission, replacing: [
			"channel.id": channelId,
			"overwrite.id": permissionOverwrite.id
			], isBot: bot)

		request.httpMethod = "PUT"
		request.httpBody = contentData
		request.setValue("application/json", forHTTPHeaderField: "Content-Type")
		request.setValue(String(contentData.count), forHTTPHeaderField: "Content-Length")

		let rateLimiterKey = DiscordRateLimitKey(endpoint: .permissions, parameters: ["channel.id": channelId])

		DiscordRateLimiter.executeRequest(request, for: rateLimiterKey, callback: {data, response, error in })
	}

	// Invites
	public static func createInvite(for channelId: String, options: [DiscordEndpointOptions.CreateInvite],
			with token: String, isBot bot: Bool, callback: @escaping (DiscordInvite?) -> Void) {
		var inviteJSON: [String: Any] = [:]

		for option in options {
			switch option {
			case let .maxAge(seconds):
				inviteJSON["max_age"] = seconds
			case let .maxUses(uses):
				inviteJSON["max_uses"] = uses
			case let .temporary(temporary):
				inviteJSON["temporary"] = temporary
			case let .unique(unique):
				inviteJSON["unique"] = unique
			}
		}

		guard let contentData = encodeJSON(inviteJSON)?.data(using: .utf8, allowLossyConversion: false) else {
			return
		}

		var request = createRequest(with: token, for: .channelInvites, replacing: [
			"channel.id": channelId
			], isBot: bot)

		request.httpMethod = "POST"
		request.httpBody = contentData
		request.setValue("application/json", forHTTPHeaderField: "Content-Type")
		request.setValue(String(contentData.count), forHTTPHeaderField: "Content-Length")

		let rateLimiterKey = DiscordRateLimitKey(endpoint: .channelInvites, parameters: ["channel.id": channelId])

		DiscordRateLimiter.executeRequest(request, for: rateLimiterKey, callback: {data, response, error in
			guard let data = data, response?.statusCode == 200 else {
				callback(nil)

				return
			}

			guard let stringData = String(data: data, encoding: .utf8), let json = decodeJSON(stringData),
				case let .dictionary(invite) = json else {
					callback(nil)

					return
			}

			print(DiscordInvite(inviteObject: invite))
		})
	}

	public static func getInvites(for channelId: String, with token: String, isBot bot: Bool,
			callback: @escaping ([DiscordInvite]) -> Void) {
		var request = createRequest(with: token, for: .channelInvites, replacing: [
			"channel.id": channelId
			], isBot: bot)

		request.httpMethod = "GET"

		let rateLimiterKey = DiscordRateLimitKey(endpoint: .channelInvites, parameters: ["channel.id": channelId])

		DiscordRateLimiter.executeRequest(request, for: rateLimiterKey, callback: {data, response, error in
			guard let data = data, response?.statusCode == 200 else {
				callback([])

				return
			}

			guard let stringData = String(data: data, encoding: .utf8), let json = decodeJSON(stringData),
				case let .array(invites) = json else {
					callback([])

					return
			}

			callback(DiscordInvite.invitesFromArray(inviteArray: invites as? [[String: Any]] ?? []))
		})
	}

	// Pinned Messages
	public static func deletePinnedMessage(_ messageId: String, on channelId: String, with token: String,
			isBot bot: Bool) {

	}

	public static func getPinnedMessages(for channelId: String, with token: String, isBot bot: Bool,
			callback: @escaping ([DiscordMessage]) -> Void) {

	}
}
