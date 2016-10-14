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
}

public enum DiscordEndpoint : String {
	case baseURL = "https://discordapp.com/api"
	case messages = "/channels/channel.id/messages"

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

	private static func doRequest(with request: URLRequest,
		callback: @escaping (Data?, URLResponse?, Error?) -> Void) {

		URLSession.shared.dataTask(with: request, completionHandler: callback).resume()
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

		doRequest(with: request, callback: {data, response, error in
			guard let response = response as? HTTPURLResponse, let data = data, response.statusCode == 200 else {
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

        doRequest(with: request, callback: {_, _, _ in })
	}
}
