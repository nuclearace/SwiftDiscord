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

public struct DiscordEndpointOptions {
	private init() {}

	public enum CreateInvite {
		case maxAge(Int)
		case maxUses(Int)
		case temporary(Int)
		case unique(Bool)
	}

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

	public enum GuildCreateChannel {
		case bitrate(Int)
		case name(String)
		case permissionOverwrites([DiscordPermissionOverwrite])
		case type(DiscordChannelType)
		case userLimit(Int)
	}

	public enum GuildGetMembers {
		case after(Int)
		case limit(Int)
	}

	public enum ModifyChannel {
		case bitrate(Int)
		case name(String)
		case position(Int)
		case topic(String)
		case userLimit(Int)
	}

	public enum ModifyGuild {
		case afkChannelId(String)
		case afkTimeout(Int)
		case defaultMessageNotifications(Int)
		case icon(String)
		case name(String)
		case ownerId(String)
		case region(String)
		case splash(String)
		case verificationLevel(Int)
	}
}

// TODO Group DM

public enum DiscordEndpoint : String {
	case baseURL = "https://discordapp.com/api"

	/* Channels */
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
	/* End channels */

	/* Guilds */
	case guilds = "/guilds/guild.id"

	// Guild Channels
	case guildChannels = "/guilds/guild.id/channels"

	// Guild Members
	case guildMembers = "/guilds/guild.id/members"
	case guildMember = "/guilds/guild.id/members/user.id"

	// Guild Bans
	case guildBans = "/guilds/guild.id/bans"
	case guildBanUser = "/guilds/guild.id/bans/user.id"

	// Guild Roles
	case guildRoles = "/guilds/guild.id/roles"
	case guildRole = "/guilds/guild.id/roles/role.id"
	/* End Guilds */

	/* User */
	case userChannels = "/users/me/channels"
	case userGuilds = "/users/me/guilds"

	var combined: String {
		return DiscordEndpoint.baseURL.rawValue + rawValue
	}

	public static func createRequest(with token: String, for endpoint: DiscordEndpoint,
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
