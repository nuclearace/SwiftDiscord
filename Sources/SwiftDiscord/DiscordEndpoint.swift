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

	static func createRequest(with token: String, for endpoint: DiscordEndpoint,
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
}
