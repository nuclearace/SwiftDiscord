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

/// A namespace struct for endpoint options.
public struct DiscordEndpointOptions {
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

// TODO Group DM

/**
    This enum controls the interface with the Discord REST API.

    It defines several endpoint cases which are then used by the various static methods defined on this enum.
    The cases themselves are of little use.

    The methods all take a `DiscordToken` which is used for authentication with the REST API.
    GET methods also take a callback.

    All requests through this enum are rate limited.

    **NOTE**: Callbacks from methods on this enum are *NOT* executed on the client's handleQueue. So it is important
    that if you make modifications to the client inside of a callback, you first dispatch back on the handleQueue.
*/
public enum DiscordEndpoint : String {
    /// The base url for the Discord REST API.
    case baseURL = "https://discordapp.com/api/v6"

    /* Channels */
    /// The base channel endpoint.
    case channel = "/channels/channel.id"

    // Messages
    /// The base channel messages endpoint.
    case messages = "/channels/channel.id/messages"

    /// The channel bulk delete endpoint.
    case bulkMessageDelete = "/channels/channel.id/messages/bulk_delete"

    /// The base channel message endpoint.
    case channelMessage = "/channels/channel.id/messages/message.id"

    /// The channel typing endpoint.
    case typing = "/channels/channel.id/typing"

    // Permissions
    /// The base channel permissions endpoint.
    case permissions = "/channels/channel.id/permissions"

    /// The channel permission endpoint.
    case channelPermission = "/channels/channel.id/permissions/overwrite.id"

    // Invites
    /// The base endpoint for invites.
    case invites = "/invites/invite.code"

    /// The base endpoint for channel invites.
    case channelInvites = "/channels/channel.id/invites"

    // Pinned Messages
    /// The base endpoint for pinned channel messages.
    case pins = "/channels/channel.id/pins"

    /// The channel pinned message endpoint.
    case pinnedMessage = "/channels/channel.id/pins/message.id"

    // Webhooks
    /// The channel webhooks endpoint.
    case channelWebhooks = "/channels/channel.id/webhooks"
    /* End channels */

    /* Guilds */
    /// The base guild endpoint.
    case guilds = "/guilds/guild.id"

    // Guild Channels
    /// The base endpoint for guild channels.
    case guildChannels = "/guilds/guild.id/channels"

    // Guild Members
    /// The base guild members endpoint.
    case guildMembers = "/guilds/guild.id/members"

    /// The guild member endpoint.
    case guildMember = "/guilds/guild.id/members/user.id"

    /// The guild member roles enpoint.
    case guildMemberRole = "/guilds/guild.id/members/user.id/roles/role.id"

    // Guild Bans
    /// The base guild bans endpoint.
    case guildBans = "/guilds/guild.id/bans"

    /// The guild ban user endpoint.
    case guildBanUser = "/guilds/guild.id/bans/user.id"

    // Guild Roles
    /// The base guild roles endpoint.
    case guildRoles = "/guilds/guild.id/roles"

    /// The guild role endpoint.
    case guildRole = "/guilds/guild.id/roles/role.id"

    // Webhooks
    /// The guilds webhooks endpoint.
    case guildWebhooks = "/guilds/guild.id/webhooks"
    /* End Guilds */

    /* User */
    /// The user channels endpoint.
    case userChannels = "/users/me/channels"

    /// The user guilds endpoint.
    case userGuilds = "/users/me/guilds"

    /* Webhooks */
    /// The single webhook endpoint.
    case webhook = "/webhooks/webhook.id"

    /// The single webhook with token endpoint.
    case webhookWithToken = "/webhooks/webhook.id/webhook.token"

    /// A slack compatible webhook.
    case webhookSlack = "/webhooks/webhook.id/webhook.token/slack"

    /// A GitHub compatible webhook.
    case webhookGithub = "/webhooks/webhook.id/webhook.token/github"
    /* End Webhooks */

    var combined: String {
        return DiscordEndpoint.baseURL.rawValue + rawValue
    }

    // MARK: Methods

    /**
        Helper method that creates the basic request for an endpoint.

        - parameter with: A DiscordToken that will be used for authentication
        - parameter for: The endpoint this request is for
        - parameter replacing: A dictionary that will be used to fill in the endpoint's url
        - parameter getParams: An optional dictionary of get parameters.

        - returns: a URLRequest that can be further customized
    */
    public static func createRequest(with token: DiscordToken, for endpoint: DiscordEndpoint,
        replacing: [String: String], getParams: [String: String]? = nil) -> URLRequest {

        var request = URLRequest(url: endpoint.createURL(replacing: replacing, getParams: getParams ?? [:]))

        request.setValue(token.token, forHTTPHeaderField: "Authorization")

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

    static func jsonFromResponse(data: Data?, response: HTTPURLResponse?) -> JSON? {
        guard let data = data, let response = response, (response.statusCode == 200 || response.statusCode == 201),
                let stringData = String(data: data, encoding: .utf8) else {
            return nil
        }

        return JSON.decodeJSON(stringData)
    }
}
