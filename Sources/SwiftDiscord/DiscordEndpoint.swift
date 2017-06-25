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

/**
 * An HTTP content-type.  Common options are available as enum values, but if you need something special, use .other("My-Special-Type")
 */
public enum HTTPContentType: CustomStringConvertible {
    case json
    case other(String)

    public var description: String {
        switch self {
        case .json:
            return "application/json"
        case let .other(type):
            return type
        }
    }
}

/**
 * An HTTP Request Method.  This includes any associated data.
 */
public enum HTTPMethod {
    case get(params: [String: String]?)
    case post(content: (Data, type: HTTPContentType)?)
    case put(content: (Data, type: HTTPContentType)?)
    case patch(content: (Data, type: HTTPContentType)?)
    case delete

    var methodString: String {
        switch self {
        case .get:
            return "GET"
        case .post:
            return "POST"
        case .put:
            return "PUT"
        case .patch:
            return "PATCH"
        case .delete:
            return "DELETE"
        }
    }
}

// TODO Group DM
// TODO Add guild member
// TODO Guild integrations
// TODO Guild pruning
// TODO Guild embeds
// TODO Guild batch modify roles

/**
    This enum defines the endpoints used to interact with the Discord API.
*/
public enum DiscordEndpoint: CustomStringConvertible {
    /// The base url for the Discord REST API.
    case baseURL

    /* Channels */
    /// The base channel endpoint.
    case channel(id: String)

    // Messages
    /// The base channel messages endpoint.
    case messages(channel: String)

    /// The channel bulk delete endpoint.
    case bulkMessageDelete(channel: String)

    /// The base channel message endpoint.
    case channelMessage(channel: String, message: String)

    /// Same as channelMessage, separate for rate limiting purposes
    case channelMessageDelete(channel: String, message: String)

    /// The channel typing endpoint.
    case typing(channel: String)

    // Permissions
    /// The base channel permissions endpoint.
    case permissions(channel: String)

    /// The channel permission endpoint.
    case channelPermission(channel: String, overwrite: String)

    // Invites
    /// The base endpoint for invites.
    case invites(code: String)

    /// The base endpoint for channel invites.
    case channelInvites(channel: String)

    // Pinned Messages
    /// The base endpoint for pinned channel messages.
    case pins(channel: String)

    /// The channel pinned message endpoint.
    case pinnedMessage(channel: String, message: String)

    // Webhooks
    /// The channel webhooks endpoint.
    case channelWebhooks(channel: String)
    /* End channels */

    /* Guilds */
    /// The base guild endpoint.
    case guilds(id: String)

    // Guild Channels
    /// The base endpoint for guild channels.
    case guildChannels(guild: String)

    // Guild Members
    /// The base guild members endpoint.
    case guildMembers(guild: String)

    /// The guild member endpoint.
    case guildMember(guild: String, user: String)

    /// The guild member roles enpoint.
    case guildMemberRole(guild: String, user: String, role: String)

    // Guild Bans
    /// The base guild bans endpoint.
    case guildBans(guild: String)

    /// The guild ban user endpoint.
    case guildBanUser(guild: String, user: String)

    // Guild Roles
    /// The base guild roles endpoint.
    case guildRoles(guild: String)

    /// The guild role endpoint.
    case guildRole(guild: String, role: String)

    // Webhooks
    /// The guilds webhooks endpoint.
    case guildWebhooks(guild: String)
    /* End Guilds */

    /* User */
    /// The user channels endpoint.
    case userChannels

    /// The user guilds endpoint.
    case userGuilds

    /* Webhooks */
    /// The single webhook endpoint.
    case webhook(id: String)

    /// The single webhook with token endpoint.
    case webhookWithToken(id: String, token: String)

    /// A slack compatible webhook.
    case webhookSlack(id: String, token: String)

    /// A GitHub compatible webhook.
    case webhookGithub(id: String, token: String)
    /* End Webhooks */

    var combined: String {
        return DiscordEndpoint.baseURL.description + description
    }

    // MARK: Endpoint string calculation

    public var description: String {
        switch self {
        case .baseURL:
			return "https://discordapp.com/api/v6"

        // -- Channels --
        case let .channel(id):
			return "/channels/\(id)"
        // Messages
        case let .messages(channel):
			return "/channels/\(channel)/messages"
        case let .bulkMessageDelete(channel):
			return "/channels/\(channel)/messages/bulk_delete"
        case let .channelMessage(channel, message):
			return "/channels/\(channel)/messages/\(message)"
        case let .channelMessageDelete(channel, message):
			return "/channels/\(channel)/messages/\(message)"
        case let .typing(channel):
			return "/channels/\(channel)/typing"
        // Permissions
        case let .permissions(channel):
			return "/channels/\(channel)/permissions"
        case let .channelPermission(channel, overwrite):
			return "/channels/\(channel)/permissions/\(overwrite)"
        // Invites
        case let .invites(code):
			return "/invites/\(code)"
        case let .channelInvites(channel):
			return "/channels/\(channel)/invites"
        // Pinned Messages
        case let .pins(channel):
			return "/channels/\(channel)/pins"
        case let .pinnedMessage(channel, message):
			return "/channels/\(channel)/pins/\(message)"
        // Webhooks
        case let .channelWebhooks(channel):
			return "/channels/\(channel)/webhooks"

        // -- Guilds --
        case let .guilds(id):
			return "/guilds/\(id)"
        // Guild Channels
        case let .guildChannels(guild):
			return "/guilds/\(guild)/channels"
        // Guild Members
        case let .guildMembers(guild):
			return "/guilds/\(guild)/members"
        case let .guildMember(guild, user):
			return "/guilds/\(guild)/members/\(user)"
        case let .guildMemberRole(guild, user, role):
			return "/guilds/\(guild)/members/\(user)/roles/\(role)"
        // Guild Bans
        case let .guildBans(guild):
			return "/guilds/\(guild)/bans"
        case let .guildBanUser(guild, user):
			return "/guilds/\(guild)/bans/\(user)"
        // Guild Roles
        case let .guildRoles(guild):
			return "/guilds/\(guild)/roles"
        case let .guildRole(guild, role):
			return "/guilds/\(guild)/roles/\(role)"
        // Webhooks
        case let .guildWebhooks(guild):
			return "/guilds/\(guild)/webhooks"

        // -- User --
        case .userChannels:
			return "/users/@me/channels"
        case .userGuilds:
			return "/users/@me/guilds"

        // -- Webhooks --
        case let .webhook(id):
			return "/webhooks/\(id)"
        case let .webhookWithToken(id, token):
			return "/webhooks/\(id)/\(token)"
        case let .webhookSlack(id, token):
			return "/webhooks/\(id)/\(token)/slack"
        case let .webhookGithub(id, token):
			return "/webhooks/\(id)/\(token)/github"
        }
    }

    // MARK: Methods

    /**
        Helper method that creates the basic request for an endpoint.

        - parameter with: A DiscordToken that will be used for authentication
        - parameter for: The endpoint this request is for
        - parameter getParams: An optional dictionary of get parameters.

        - returns: a URLRequest that can be further customized
    */
    public func createRequest(with token: DiscordToken, method: HTTPMethod) -> URLRequest? {

        let getParams: [String: String]?
        if case let .get(params) = method {
            getParams = params
        } else {
            getParams = nil
        }

        guard let url = self.createURL(getParams: getParams) else { return nil }
        var request = URLRequest(url: url)

        request.setValue(token.token, forHTTPHeaderField: "Authorization")
        request.httpMethod = method.methodString

        var content: (Data, type: HTTPContentType)? = nil
        if case let .post(optionalContent) = method {
            content = optionalContent
        } else if case let .put(optionalContent) = method {
            content = optionalContent
        } else if case let .patch(optionalContent) = method {
            content = optionalContent
        }
        if let content = content {
            request.httpBody = content.0
            request.setValue(String(describing: content.type), forHTTPHeaderField: "Content-Type")
            request.setValue(String(content.0.count), forHTTPHeaderField: "Content-Length")
        }

        return request
    }

    private func createURL(getParams: [String: String]?) -> URL? {

        // This can fail, specifically if you try to include a non-url-encoded emoji in it
        guard let url = URL(string: self.combined) else {
            DefaultDiscordLogger.Logger.error("Couldn't convert \"\(self.combined)\" to a URL.  This shouldn't happen.", type: "DiscordEndpoint")
            return nil
        }

        if let getParams = getParams {
            guard var com = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
                DefaultDiscordLogger.Logger.error("Couldn't convert \"\(url)\" to URLComponents.  This shouldn't happen.", type: "DiscordEndpoint")
                return nil
            }

            com.queryItems = getParams.map({ URLQueryItem(name: $0.key, value: $0.value) })

            return com.url!
        } else {
            return url
        }
    }
}

public extension DiscordEndpoint {
    /// A namespace struct for endpoint options.
    public struct Options {
        private init() {}

        /// Create invite options.
        public enum CreateInvite {
            /// How long this invite should live.
            case maxAge(Int)

            /// Number of uses this invite has before it becomes invalid
            case maxUses(Int)

            /// Whether this invite only grant temporary membership
            case temporary(Bool)

            /// if true, don't try to reuse a similar invite (useful for creating many unique one time use invites)
            case unique(Bool)
        }

        /// Options for creating a role. All are optional.
        public enum CreateRole {
            /// The color of the enum.
            case color(Int)

            /// Whether the role should be displayed separately in the sidebar.
            case hoist(Bool)

            /// Whether this role is mentionable.
            case mentionable(Bool)

            /// The name of this role.
            case name(String)

            /// The permissions this role has.
            case permissions(Int)
        }

        /// Get message options.
        ///
        /// after, around and before are mutually exclusive. They shouldn't be in the same get request
        public enum GetMessage {
            /// The message to get other messages after.
            case after(DiscordMessage)

            /// The message to get other messages around.
            case around(DiscordMessage)

            /// The message to get other messages before.
            case before(DiscordMessage)

            /// The number of messages to get.
            case limit(Int)
        }

        /// Guild create channel options.
        public enum GuildCreateChannel {
            /// The bitrate of a voice channel.
            case bitrate(Int)

            /// The name of the channel.
            case name(String)

            /// An array of permissions for this channel.
            case permissionOverwrites([DiscordPermissionOverwrite])

            /// The type of this channel.
            case type(DiscordChannelType)

            /// The user limit for a voice channel
            case userLimit(Int)
        }

        /// Guild get members options.
        public enum GuildGetMembers {
            /// The user index to get users after (pagination).
            case after(Int)

            /// The number of users to get.
            case limit(Int)
        }

        /// Modify channel options.
        public enum ModifyChannel {
            /// The bitrate of a voice channel.
            case bitrate(Int)

            /// The name of the channel.
            case name(String)

            /// The position of this channel.
            case position(Int)

            /// The topic of a text channel.
            case topic(String)

            /// The user limit of a voice channel.
            case userLimit(Int)
        }

        /// Modify a guild member.
        public enum ModifyMember {
            /// The id of the channel to move this member to. If they're connected to voice.
            case channel(String)

            /// Whether this member is deafened.
            case deaf(Bool)

            /// Whether this member is muted.
            case mute(Bool)

            /// The nick for this member.
            case nick(String?)

            /// The roles this member should have.
            case roles([DiscordRole])
        }

        /// Modify guild options.
        public enum ModifyGuild {
            /// The snowflake id of the afk channel.
            case afkChannelId(String)

            /// The length of time before a user is sent to the afk channel.
            case afkTimeout(Int)

            /// The default notification setting.
            case defaultMessageNotifications(Int)

            /// A base64 encoded string of the guild icon.
            case icon(String)

            /// The name of the guild.
            case name(String)

            /// The snowflake id of the new guild owner.
            case ownerId(String)

            /// The region this guild is in.
            case region(String)

            /// The base64 encoded splash image for this guild.
            case splash(String)

            /// The required verification level of this guild.
            case verificationLevel(Int)
        }

        /// The options for creating/editing a webhook.
        public enum WebhookOption {
            /// The name of the webhook
            case name(String)

            /// The avatar of the webhook. A base64 128x128 jpeg image.
            case avatar(String)
        }
    }
}
