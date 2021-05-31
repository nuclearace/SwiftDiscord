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
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import Logging

fileprivate let logger = Logger(label: "DiscordEndpoint")

// TODO Group DM
// TODO Add guild member
// TODO Guild integrations
// TODO Guild pruning
// TODO Guild embeds
// TODO Guild batch modify roles

///
/// This enum defines the endpoints used to interact with the Discord API.
///
public enum DiscordEndpoint : CustomStringConvertible {
    /// The base url for the Discord REST API.
    case baseURL

    /* Channels */
    /// The base channel endpoint.
    case channel(id: ChannelID)

    // Messages
    /// The base channel messages endpoint.
    case messages(channel: ChannelID)

    /// The channel bulk delete endpoint.
    case bulkMessageDelete(channel: ChannelID)

    /// The base channel message endpoint.
    case channelMessage(channel: ChannelID, message: MessageID)

    /// Same as channelMessage, separate for rate limiting purposes
    case channelMessageDelete(channel: ChannelID, message: MessageID)

    /// The channel typing endpoint.
    case typing(channel: ChannelID)

    // Reactions
    /// The endpoint for creating/deleting own reactions.
    case reactions(channel: ChannelID, message: MessageID, emoji: String)
    
    /// The endpoint for another user's reactions
    case userReactions(channel: ChannelID, message: MessageID, emoji: String, user: UserID)

    // Permissions
    /// The base channel permissions endpoint.
    case permissions(channel: ChannelID)

    /// The channel permission endpoint.
    case channelPermission(channel: ChannelID, overwrite: OverwriteID)

    // Invites
    /// The base endpoint for invites.
    case invites(code: String)

    /// The base endpoint for channel invites.
    case channelInvites(channel: ChannelID)

    // Pinned Messages
    /// The base endpoint for pinned channel messages.
    case pins(channel: ChannelID)

    /// The channel pinned message endpoint.
    case pinnedMessage(channel: ChannelID, message: MessageID)

    // Webhooks
    /// The channel webhooks endpoint.
    case channelWebhooks(channel: ChannelID)
    /* End channels */

    /* Guilds */
    /// The base guild endpoint.
    case guilds(id: GuildID)

    /// Guild audit log
    case guildAuditLog(id: GuildID)

    // Guild Channels
    /// The base endpoint for guild channels.
    case guildChannels(guild: GuildID)

    // Guild Members
    /// The base guild members endpoint.
    case guildMembers(guild: GuildID)

    /// The guild member endpoint.
    case guildMember(guild: GuildID, user: UserID)

    /// The guild member roles enpoint.
    case guildMemberRole(guild: GuildID, user: UserID, role: RoleID)

    // Guild Bans
    /// The base guild bans endpoint.
    case guildBans(guild: GuildID)

    /// The guild ban user endpoint.
    case guildBanUser(guild: GuildID, user: UserID)

    // Guild Roles
    /// The base guild roles endpoint.
    case guildRoles(guild: GuildID)

    /// The guild role endpoint.
    case guildRole(guild: GuildID, role: RoleID)

    // Webhooks
    /// The guilds webhooks endpoint.
    case guildWebhooks(guild: GuildID)
    /* End Guilds */

    /* User */
    /// The user channels endpoint.
    case userChannels

    /// The user guilds endpoint.
    case userGuilds
    /* End User */

    /* Webhooks */
    /// The single webhook endpoint.
    case webhook(id: WebhookID)

    /// The single webhook with token endpoint.
    case webhookWithToken(id: WebhookID, token: String)

    /// A slack compatible webhook.
    case webhookSlack(id: WebhookID, token: String)

    /// A GitHub compatible webhook.
    case webhookGithub(id: WebhookID, token: String)
    /* End Webhooks */

    /* Emoji */
    // The guild's emojis endpoint.
    case guildEmojis(guild: GuildID)

    // The guild's emoji endpoint
    case guildEmoji(guild: GuildID, emoji: EmojiID)
    /* End Emoji */


    /* Applications */
    /// The global slash-commands endpoint.
    case globalApplicationCommands(applicationId: ApplicationID)

    /// The endpoint for a specific global slash-command.
    case globalApplicationCommand(applicationId: ApplicationID, commandId: CommandID)

    /// The guild-specific slash-commands endpoint.
    case guildApplicationCommands(applicationId: ApplicationID, guildId: GuildID)

    /// The endpoint for a specific guild-specific slash-command.
    case guildApplicationCommand(applicationId: ApplicationID, guildId: GuildID, commandId: CommandID)
    /* End Application */

    /* Interactions */
    case interactionsCallback(interactionId: InteractionID, interactionToken: String)
    /* End Interactions */

    var combined: String {
        return DiscordEndpoint.baseURL.description + description
    }
}

public extension DiscordEndpoint {
    // MARK: Endpoint Request enum

    ///
    /// * An HTTP Request for an Endpoint.  This includes any associated data.
    ///
    enum EndpointRequest {
        /// A GET request.
        case get(params: [String: String]?, extraHeaders: [DiscordHeader: String]?)

        /// A POST request.
        case post(content: HTTPContent?, extraHeaders: [DiscordHeader: String]?)

        /// A PUT request.
        case put(content: HTTPContent?, extraHeaders: [DiscordHeader: String]?)

        /// A PATCH request.
        case patch(content: HTTPContent?, extraHeaders: [DiscordHeader: String]?)

        /// A DELETE request.
        case delete(content: HTTPContent?, extraHeaders: [DiscordHeader: String]?)

        var methodString: String {
            switch self {
            case .get:      return "GET"
            case .post:     return "POST"
            case .put:      return "PUT"
            case .patch:    return "PATCH"
            case .delete:   return "DELETE"
            }
        }

        ///
        /// Helper method that creates the basic request for an endpoint.
        ///
        /// - parameter with: A DiscordToken that will be used for authentication
        /// - parameter endpoint: The endpoint this request is for
        ///
        /// - returns: a URLRequest that can be further customized
        ///
        public func createRequest(with token: DiscordToken,
                                  endpoint: DiscordEndpoint) -> URLRequest? {
            let getParams: [String: String]?

            if case let .get(params, _) = self {
                getParams = params
            } else {
                getParams = nil
            }

            guard let url = endpoint.createURL(getParams: getParams) else { return nil }
            var request = URLRequest(url: url)

            request.setValue(token.token, forHTTPHeaderField: "Authorization")
            request.httpMethod = methodString

            addContent(to: &request)

            return request
        }

        private func addContent(to request: inout URLRequest) {
            let content: HTTPContent?
            let extraHeaders: [DiscordHeader: String]?
            let requiresBody: Bool

            switch self {
            case let .get(_, headers?):
                (content, extraHeaders, requiresBody) = (nil, headers, false)
            case let .post(optionalContent, headers):
                (content, extraHeaders, requiresBody) = (optionalContent, headers, true)
            case let .put(optionalContent, headers):
                (content, extraHeaders, requiresBody) = (optionalContent, headers, true)
            case let .patch(optionalContent, headers):
                (content, extraHeaders, requiresBody) = (optionalContent, headers, true)
            case let .delete(optionalContent, headers):
                (content, extraHeaders, requiresBody) = (optionalContent, headers, false)
            default:
                (content, extraHeaders, requiresBody) = (nil, nil, false)
            }

            for (header, value) in extraHeaders ?? [:] {
                request.setValue(value.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed),
                                 forHTTPHeaderField: header.rawValue)
            }

            switch content {
            case nil:
                if requiresBody {
                    request.httpBody = Data()
                    request.setValue("0", forHTTPHeaderField: "Content-Length")
                }
            case let .json(data)?:
                request.httpBody = data
                request.setValue(HTTPContent.jsonType, forHTTPHeaderField: "Content-Type")
                request.setValue(String(data.count), forHTTPHeaderField: "Content-Length")
            case let .other(type, body)?:
                request.httpBody = body
                request.setValue(type, forHTTPHeaderField: "Content-Type")
                request.setValue(String(body.count), forHTTPHeaderField: "Content-Length")
            }
        }
    }

    // MARK: Endpoint string calculation

    var description: String {
        switch self {
        case .baseURL:
            return "https://discord.com/api/v8"

        /* Channels */
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
        // Reactions
        case let .reactions(channel, message, emoji):
            return "/channels/\(channel)/messages/\(message)/reactions/\(emoji)/@me"
        case let .userReactions(channel, message, emoji, user):
            return "/channels/\(channel)/messages/\(message)/reactions/\(emoji)/\(user)"
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
        /* End Channels */

        /* Guilds */
        case let .guilds(id):
            return "/guilds/\(id)"
        case let .guildAuditLog(id):
            return "/guilds/\(id)/audit-logs"
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
        /* End Guilds */

        /* User */
        case .userChannels:
            return "/users/@me/channels"
        case .userGuilds:
            return "/users/@me/guilds"
        /* End User */

        /* Webhooks */
        case let .webhook(id):
            return "/webhooks/\(id)"
        case let .webhookWithToken(id, token):
            return "/webhooks/\(id)/\(token)"
        case let .webhookSlack(id, token):
            return "/webhooks/\(id)/\(token)/slack"
        case let .webhookGithub(id, token):
            return "/webhooks/\(id)/\(token)/github"
        /* End Webhooks */

        /* Emoji */
        case let .guildEmojis(guild):
            return "/guilds/\(guild)/emojis"
        case let .guildEmoji(guild, emoji):
            return "/guilds/\(guild)/emojis/\(emoji)"
        /* End Emoji */

        /* Application */
        case let .globalApplicationCommands(applicationId):
            return "/applications/\(applicationId)/commands"
        case let .globalApplicationCommand(applicationId, commandId):
            return "/applications/\(applicationId)/commands/\(commandId)"
        case let .guildApplicationCommands(applicationId, guildId):
            return "/applications/\(applicationId)/guilds/\(guildId)/commands"
        case let .guildApplicationCommand(applicationId, guildId, commandId):
            return "/applications/\(applicationId)/guilds/\(guildId)/commands/\(commandId)"
        /* End Application */

        /* Interactions */
        case let .interactionsCallback(interactionId, interactionToken):
            return "/interactions/\(interactionId)/\(interactionToken)/callback"
        /* End Interactions */
        }
    }

    /// Gets a rate limit key for the endpoint
    internal var rateLimitKey: DiscordRateLimitKey {
        // To add a new endpoint's rate limit key:
        // If the endpoint includes a channel id or guild id, supply that as that as the id parameter.
        // Otherwise, skip it.  Since a channel id implies a guild id, we should never need both
        // For the urlParts, go through the list of slash-separated pieces of the endpoint URL and add
        // the enum case associated with each of them, adding a case to the enum if it doesn't already exist
        // Example: "/webhooks/\(id)/\(token)/github" -> [.webhooks, .webhookID, .webhookToken, .github]
        // Example: "/guilds/\(guild)/channels" -> [.guilds, .guildID, .channels]
        // Example: "/users/@me/guilds" -> [.users, .userID, .guilds] ("@me" is a user id)

        switch self {
        case .baseURL:
            fatalError("Attempted to get rate limit key for base URL")
        /* Channels */
        case let .channel(id):
            return DiscordRateLimitKey(id: id, urlParts: [.channels, .channelID])
        // Messages
        case let .messages(channel):
            return DiscordRateLimitKey(id: channel, urlParts: [.channels, .channelID, .messages])
        case let .bulkMessageDelete(channel):
            return DiscordRateLimitKey(id: channel, urlParts: [.channels, .channelID, .bulkDelete])
        case let .channelMessage(channel, _):
            return DiscordRateLimitKey(id: channel, urlParts: [.channels, .channelID, .messages, .messageID])
        case let .channelMessageDelete(channel, _):
            return DiscordRateLimitKey(id: channel, urlParts: [.channels, .channelID, .messagesDelete, .messageID])
        case let .typing(channel):
            return DiscordRateLimitKey(id: channel, urlParts: [.channels, .channelID, .typing])
        // Reactions
        case let .reactions(channel, _, _):
            return DiscordRateLimitKey(id: channel, urlParts: [.channels, .channelID, .messages, .messageID, .reactions, .emoji, .me])
        case let .userReactions(channel, _, _, _):
            return DiscordRateLimitKey(id: channel, urlParts: [.channels, .channelID, .messages, .messageID, .reactions, .emoji, .userID])
        // Permissions
        case let .permissions(channel):
            return DiscordRateLimitKey(id: channel, urlParts: [.channels, .channelID, .permissions])
        case let .channelPermission(channel, _):
            return DiscordRateLimitKey(id: channel, urlParts: [.channels, .channelID, .permissions, .overwriteID])
        // Invites
        case .invites:
            return DiscordRateLimitKey(urlParts: [.invites, .inviteCode])
        case let .channelInvites(channel):
            return DiscordRateLimitKey(id: channel, urlParts: [.channels, .channelID, .invites])
        // Pinned Messages
        case let .pins(channel):
            return DiscordRateLimitKey(id: channel, urlParts: [.channels, .channelID, .pins])
        case let .pinnedMessage(channel, _):
            return DiscordRateLimitKey(id: channel, urlParts: [.channels, .channelID, .pins, .messageID])
        // Webhooks
        case let .channelWebhooks(channel):
            return DiscordRateLimitKey(id: channel, urlParts: [.channels, .channelID, .webhooks])
        /* End Channels */

        /* Guilds */
        case let .guilds(id):
            return DiscordRateLimitKey(id: id, urlParts: [.guilds, .guildID])
        case let .guildAuditLog(id):
            return DiscordRateLimitKey(id: id, urlParts: [.guilds, .guildID, .auditLog])
        // Guild Channels
        case let .guildChannels(guild):
            return DiscordRateLimitKey(id: guild, urlParts: [.guilds, .guildID, .channels])
        // Guild Members
        case let .guildMembers(guild):
            return DiscordRateLimitKey(id: guild, urlParts: [.guilds, .guildID, .members])
        case let .guildMember(guild, _):
            return DiscordRateLimitKey(id: guild, urlParts: [.guilds, .guildID, .members, .userID])
        case let .guildMemberRole(guild, _, _):
            return DiscordRateLimitKey(id: guild, urlParts: [.guilds, .guildID, .members, .userID, .roles, .roleID])
        // Guild Bans
        case let .guildBans(guild):
            return DiscordRateLimitKey(id: guild, urlParts: [.guilds, .guildID, .bans])
        case let .guildBanUser(guild, _):
            return DiscordRateLimitKey(id: guild, urlParts: [.guilds, .guildID, .bans, .userID])
        // Guild Roles
        case let .guildRoles(guild):
            return DiscordRateLimitKey(id: guild, urlParts: [.guilds, .guildID, .roles])
        case let .guildRole(guild, _):
            return DiscordRateLimitKey(id: guild, urlParts: [.guilds, .guildID, .roles, .roleID])
        // Webhooks
        case let .guildWebhooks(guild):
            return DiscordRateLimitKey(id: guild, urlParts: [.guilds, .guildID, .webhooks])
        /* End Guilds */

        /* User */
        case .userChannels:
            return DiscordRateLimitKey(urlParts: [.users, .userID, .channels])
        case .userGuilds:
            return DiscordRateLimitKey(urlParts: [.users, .userID, .guilds])
        /* End User */

        /* Webhooks */
        case .webhook:
            return DiscordRateLimitKey(urlParts: [.webhooks, .webhookID])
        case .webhookWithToken:
            return DiscordRateLimitKey(urlParts: [.webhooks, .webhookID, .webhookToken])
        case .webhookSlack:
            return DiscordRateLimitKey(urlParts: [.webhooks, .webhookID, .webhookToken, .slack])
        case .webhookGithub:
            return DiscordRateLimitKey(urlParts: [.webhooks, .webhookID, .webhookToken, .github])
        /* End Webhooks */

        /* Emoji */
        case let .guildEmojis(guild):
            return DiscordRateLimitKey(id: guild, urlParts: [.guilds, .guildID, .emojis])
        case let .guildEmoji(guild, _):
            return DiscordRateLimitKey(id: guild, urlParts: [.guilds, .guildID, .emojis, .emojiID])

        /* Applications */
        case let .globalApplicationCommands(applicationId):
            return DiscordRateLimitKey(id: applicationId, urlParts: [.applications, .applicationID, .commands])
        case let .globalApplicationCommand(applicationId, _):
            return DiscordRateLimitKey(id: applicationId, urlParts: [.applications, .applicationID, .commands, .commandID])
        case let .guildApplicationCommands(applicationId, _):
            return DiscordRateLimitKey(id: applicationId, urlParts: [.applications, .applicationID, .guilds, .guildID, .commands])
        case let .guildApplicationCommand(applicationId, _, _):
            return DiscordRateLimitKey(id: applicationId, urlParts: [.applications, .applicationID, .guilds, .guildID, .commands, .commandID])
        /* End Applications */

        /* Interactions */
        case let .interactionsCallback(interactionId, _):
            return DiscordRateLimitKey(id: interactionId, urlParts: [.interactions, .interactionID, .interactionToken, .callback])
        /* End Interactions */
        }
    }

    // MARK: Methods

    private func createURL(getParams: [String: String]?) -> URL? {
        // This can fail, specifically if you try to include a non-url-encoded emoji in it
        guard let url = URL(string: self.combined) else {
            logger.error("Couldn't convert \"\(self.combined)\" to a URL.  This shouldn't happen.")
            return nil
        }

        guard let getParams = getParams else { return url }
        guard var com = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            logger.error("Couldn't convert \"\(url)\" to URLComponents. This shouldn't happen.")
            return nil
        }

        com.queryItems = getParams.map({ URLQueryItem(name: $0.key, value: $0.value) })

        return com.url!
    }
}

///
/// * A type representing HTTP content.
///
public enum HTTPContent : CustomStringConvertible {
    /// JSON Content-Type.
    case json(Data)

    /// Other Content-Type.
    case other(type: String, body: Data)

    /// JSON MIME-type.
    public static let jsonType = "application/json"

    public var description: String {
        switch self {
        case .json:
            return HTTPContent.jsonType
        case let .other(type, _):
            return type
        }
    }
}

/// Represents the custom headers that Discord uses.
public enum DiscordHeader : String {
    /// The header that adds audit log reasons.
    case auditReason = "X-Audit-Log-Reason"
}

public extension DiscordEndpoint {
    /// A namespace struct for endpoint options.
    struct Options {
        private init() {}

        /// Options when getting an audit log.
        public enum AuditLog {
            /// Action type.
            case actionType(DiscordAuditLogActionType)

            /// Actions before a specific time.
            case before(Snowflake)

            /// The max num of entries. Default 50. Min 1. Max 100.
            case limit(Int)

            /// Filters for a specific user.
            case userId(Snowflake)
        }

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
            case permissions(DiscordPermission)
        }

        /// Options for getting messages
        public enum MessageSelection {
            /// Messages after the given ID
            case after(MessageID)

            /// Messages around the given ID
            case around(MessageID)

            /// Messages before the given ID
            case before(MessageID)

            internal var messageParam: (String, MessageID) {
                switch self {
                case let .after(message):
                    return ("after", message)
                case let .around(message):
                    return ("around", message)
                case let .before(message):
                    return ("before", message)
                }
            }
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
