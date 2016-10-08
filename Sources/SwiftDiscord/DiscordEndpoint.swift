import Foundation

public enum DiscordEndpoint : String {
	case baseURL = "https://discordapp.com/api"
	case createMessage = "/channels/channel.id/messages"

	var combined: String {
		return DiscordEndpoint.baseURL.rawValue + self.rawValue
	}

	private static func createRequest(with token: String, for endpoint: DiscordEndpoint, 
		replacing: [String: String]) -> URLRequest {
		var combined = endpoint.combined

		for (key, value) in replacing {
			combined = combined.replacingOccurrences(of: key, with: value)
		}

		var request = URLRequest(url: URL(string: combined)!)

		request.setValue(token, forHTTPHeaderField: "Authorization")
		request.setValue("application/json", forHTTPHeaderField: "Content-Type")

		return request
	}

	private static func doRequest(with request: URLRequest) {
		URLSession.shared.dataTask(with: request).resume()
	}

	public static func sendMessage(_ content: String, with token: String, to channel: String, tts: Bool) {
		let messageObject: [String: Any] = [
			"content": content,
			"tts": tts
		]

		guard let contentData = encodeJSON(messageObject)?.data(using: .utf8, allowLossyConversion: false)! else {
			return 
		}

		var request = createRequest(with: token, for: .createMessage, replacing: ["channel.id": channel])

		request.httpMethod = "POST"
		request.httpBody = contentData
        request.setValue(String(contentData.count), forHTTPHeaderField: "Content-Length")

        doRequest(with: request)
	}
}
