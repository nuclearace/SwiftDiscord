// The MIT License (MIT)
// Copyright (c) 2017 Erik Little

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

public extension DiscordEndpointConsumer where Self: DiscordUserActor {
    /// Default implementation
    public func addGuildMemberRole(_ roleId: RoleID,
                                   to userId: UserID,
                                   on guildId: GuildID,
                                   reason: String? = nil,
                                   callback: ((Bool) -> ())?) {
        var extraHeaders = [DiscordHeader: String]()

        if let modifyReason = reason {
            extraHeaders[.auditReason] = modifyReason
        }

        rateLimiter.executeRequest(endpoint: .guildMemberRole(guild: guildId, user: userId, role: roleId),
                                   token: token,
                                   requestInfo: .put(content: nil, extraHeaders: extraHeaders),
                                   callback: { _, response, _ in callback?(response?.statusCode == 204) })
    }

    /// Default implementation
    public func createGuildChannel(on guildId: GuildID,
                                   options: [DiscordEndpoint.Options.GuildCreateChannel],
                                   reason: String? = nil,
                                   callback: ((DiscordGuildChannel?) -> ())? = nil) {
        var createJSON: [String: Encodable] = [:]
        var extraHeaders = [DiscordHeader: String]()

        if let modifyReason = reason {
            extraHeaders[.auditReason] = modifyReason
        }

        for option in options {
            switch option {
            case let .bitrate(bps):
                createJSON["bitrate"] = bps
            case let .name(name):
                createJSON["name"] = name
            case let .permissionOverwrites(overwrites):
                createJSON["permission_overwrites"] = overwrites
            case let .type(type):
                createJSON["type"] = type.rawValue
            case let .userLimit(limit):
                createJSON["user_limit"] = limit
            }
        }

        guard let contentData = JSON.encodeJSONData(GenericEncodableDictionary(createJSON)) else { return }

        let requestCallback: DiscordRequestCallback = { data, response, error in
            guard case let .object(channel)? = JSON.jsonFromResponse(data: data, response: response) else {
                callback?(nil)

                return
            }

            callback?(guildChannel(fromObject: channel, guildID: guildId))
        }

        rateLimiter.executeRequest(endpoint: .guildChannels(guild: guildId),
                                   token: token,
                                   requestInfo: .post(content: .json(contentData), extraHeaders: extraHeaders),
                                   callback: requestCallback)
    }

    /// Default implementation
    public func createGuildRole(on guildId: GuildID,
                                withOptions options: [DiscordEndpoint.Options.CreateRole] = [],
                                reason: String? = nil,
                                callback: @escaping (DiscordRole?) -> ()) {
        var roleData: [String: Any] = [:]
        var extraHeaders = [DiscordHeader: String]()

        if let modifyReason = reason {
            extraHeaders[.auditReason] = modifyReason
        }

        for option in options {
            switch option {
            case let .color(color):
                roleData["color"] = color
            case let .hoist(hoist):
                roleData["hoist"] = hoist
            case let .mentionable(mentionable):
                roleData["mentionable"] = mentionable
            case let .name(name):
                roleData["name"] = name
            case let .permissions(permissions):
                roleData["permissions"] = permissions
            }
        }

        DefaultDiscordLogger.Logger.log("Creating a new role on \(guildId)", type: "DiscordEndpointGuild")
        DefaultDiscordLogger.Logger.verbose("Role options \(roleData)", type: "DiscordEndpointGuild")

        guard let contentData = JSON.encodeJSONData(roleData) else { return callback(nil) }

        let requestCallback: DiscordRequestCallback = { data, response, error in
            guard case let .object(role)? = JSON.jsonFromResponse(data: data, response: response) else {
                callback(nil)

                return
            }

            callback(DiscordRole(roleObject: role))
        }

        rateLimiter.executeRequest(endpoint: .guildRoles(guild: guildId),
                                   token: token,
                                   requestInfo: .post(content: .json(contentData), extraHeaders: extraHeaders),
                                   callback: requestCallback)
    }

    /// Default implementation
    public func deleteGuild(_ guildId: GuildID, callback: ((DiscordGuild?) -> ())? = nil) {
        let requestCallback: DiscordRequestCallback = { data, response, error in
            guard case let .object(guild)? = JSON.jsonFromResponse(data: data, response: response) else {
                callback?(nil)

                return
            }

            callback?(DiscordGuild(guildObject: guild, client: nil))
        }

        rateLimiter.executeRequest(endpoint: .guilds(id: guildId),
                                   token: token,
                                   requestInfo: .delete(content: nil, extraHeaders: nil),
                                   callback: requestCallback)
    }

    /// Default implementation.
    func getGuildAuditLog(for guildId: GuildID, withOptions options: [DiscordEndpoint.Options.AuditLog],
                          callback: @escaping (DiscordAuditLog?) -> ()) {
        DefaultDiscordLogger.Logger.debug("Getting audit log for \(guildId)", type: "DiscordEndpointGuild")

        var getParams = [String: String]()

        for option in options {
            switch option {
            case let .actionType(type):
                getParams["action_type"] = String(type.rawValue)
            case let .before(id):
                getParams["before"] = String(id.rawValue)
            case let .limit(i) where i > 0 && i <= 100:
                getParams["limit"] = String(i)
            case let .userId(id):
                 getParams["user_id"] = String(id.rawValue)
            default:
                continue
            }
        }

        let requestCallback: DiscordRequestCallback = {data, response, error in
            guard case let .object(log)? = JSON.jsonFromResponse(data: data, response: response) else {
                callback(nil)

                return
            }

            DefaultDiscordLogger.Logger.debug("Got audit log for \(guildId)", type: "DiscordEndpointGuild")

            callback(DiscordAuditLog(auditLogObject: log))
        }

        rateLimiter.executeRequest(endpoint: .guildAuditLog(id: guildId),
                                   token: token,
                                   requestInfo: .get(params: getParams, extraHeaders: nil),
                                   callback: requestCallback)
    }

    /// Default implementation
    public func getGuildBans(for guildId: GuildID, callback: @escaping ([DiscordBan]) -> ()) {
        let requestCallback: DiscordRequestCallback = { data, response, error in
            guard case let .array(bans)? = JSON.jsonFromResponse(data: data, response: response) else {
                callback([])

                return
            }

            DefaultDiscordLogger.Logger.debug("Got guild bans \(bans)", type: "DiscordEndpointGuild")
            callback(DiscordBan.bansFromArray(bans as! [[String: Any]]))
        }

        rateLimiter.executeRequest(endpoint: .guildBans(guild: guildId),
                                   token: token,
                                   requestInfo: .get(params: nil, extraHeaders: nil),
                                   callback: requestCallback)
    }

    /// Default implementation
    public func getGuildChannels(_ guildId: GuildID, callback: @escaping ([DiscordGuildChannel]) -> ()) {
        let requestCallback: DiscordRequestCallback = { data, response, error in
            guard case let .array(channels)? = JSON.jsonFromResponse(data: data, response: response) else {
                callback([])

                return
            }

            callback(guildChannels(fromArray: channels as! [[String: Any]], guildID: guildId).map({ $0.value }))
        }

        rateLimiter.executeRequest(endpoint: .guildChannels(guild: guildId),
                                   token: token,
                                   requestInfo: .get(params: nil, extraHeaders: nil),
                                   callback: requestCallback)
    }

    /// Default implementation
    public func getGuildMember(by id: UserID, on guildId: GuildID, callback: @escaping (DiscordGuildMember?) -> ()) {
        let requestCallback: DiscordRequestCallback = { data, response, error in
            guard case let .object(member)? = JSON.jsonFromResponse(data: data, response: response) else {
                callback(nil)

                return
            }

            callback(DiscordGuildMember(guildMemberObject: member, guildId: guildId))
        }

        rateLimiter.executeRequest(endpoint: .guildMember(guild: guildId, user: id),
                                   token: token,
                                   requestInfo: .get(params: nil, extraHeaders: nil),
                                   callback: requestCallback)
    }

    /// Default implementation
    public func getGuildMembers(on guildId: GuildID, options: [DiscordEndpoint.Options.GuildGetMembers],
                                callback: @escaping ([DiscordGuildMember]) -> ()) {
        var getParams: [String: String] = [:]

        for option in options {
            switch option {
            case let .after(highest):
                getParams["after"] = String(highest)
            case let .limit(number):
                getParams["limit"] = String(number)
            }
        }

        let requestCallback: DiscordRequestCallback = { data, response, error in
            guard case let .array(members)? = JSON.jsonFromResponse(data: data, response: response) else {
                callback([])

                return
            }

            let guildMembers = DiscordGuildMember.guildMembersFromArray(members as! [[String: Any]],
                                                                        withGuildId: guildId, guild: nil)
            callback(guildMembers.map({ $0.1 }))
        }

        rateLimiter.executeRequest(endpoint: .guildMembers(guild: guildId),
                                   token: token,
                                   requestInfo: .get(params: getParams, extraHeaders: nil),
                                   callback: requestCallback)
    }

    /// Default implementation
    public func getGuildRoles(for guildId: GuildID, callback: @escaping ([DiscordRole]) -> ()) {
        let requestCallback: DiscordRequestCallback = { data, response, error in
            guard case let .array(roles)? = JSON.jsonFromResponse(data: data, response: response) else {
                callback([])

                return
            }

            callback(DiscordRole.rolesFromArray(roles as! [[String: Any]]).map({ $0.value }))
        }

        rateLimiter.executeRequest(endpoint: .guildRoles(guild: guildId),
                                   token: token,
                                   requestInfo: .get(params: nil, extraHeaders: nil),
                                   callback: requestCallback)
    }

    /// Default implementation
    public func guildBan(userId: UserID,
                         on guildId: GuildID,
                         deleteMessageDays: Int = 7,
                         reason: String? = nil,
                         callback: ((Bool) -> ())? = nil) {
        guard let contentData = JSON.encodeJSONData(["delete-message-days": deleteMessageDays]) else { return }
        var extraHeaders = [DiscordHeader: String]()

        if let modifyReason = reason {
            extraHeaders[.auditReason] = modifyReason
        }

        rateLimiter.executeRequest(endpoint: .guildBanUser(guild: guildId, user: userId),
                                   token: token,
                                   requestInfo: .put(content: .json(contentData), extraHeaders: extraHeaders),
                                   callback: { _, response, _ in callback?(response?.statusCode == 204) })
    }

    /// Default implementation
    public func modifyGuild(_ guildId: GuildID,
                            options: [DiscordEndpoint.Options.ModifyGuild],
                            reason: String? = nil,
                            callback: ((DiscordGuild?) -> ())? = nil) {
        var modifyJSON: [String: Any] = [:]
        var extraHeaders = [DiscordHeader: String]()

        if let modifyReason = reason {
            extraHeaders[.auditReason] = modifyReason
        }

        for option in options {
            switch option {
            case let .afkChannelId(id):
                modifyJSON["afk_channel_id"] = id
            case let .afkTimeout(seconds):
                modifyJSON["afk_timeout"] = seconds
            case let .defaultMessageNotifications(level):
                modifyJSON["default_message_notifications"] = level
            case let .icon(icon):
                modifyJSON["icon"] = icon
            case let .name(name):
                modifyJSON["name"] = name
            case let .ownerId(id):
                modifyJSON["owner_id"] = id
            case let .region(region):
                modifyJSON["region"] = region
            case let .splash(splash):
                modifyJSON["splash"] = splash
            case let .verificationLevel(level):
                modifyJSON["verification_level"] = level
            }
        }

        guard let contentData = JSON.encodeJSONData(modifyJSON) else { return }

        let requestCallback: DiscordRequestCallback = { data, response, error in
            guard case let .object(guild)? = JSON.jsonFromResponse(data: data, response: response) else {
                callback?(nil)

                return
            }

            callback?(DiscordGuild(guildObject: guild, client: nil))
        }

        rateLimiter.executeRequest(endpoint: .guilds(id: guildId),
                                   token: token,
                                   requestInfo: .patch(content: .json(contentData), extraHeaders: extraHeaders),
                                   callback: requestCallback)
    }

    /// Default implementation
    public func modifyGuildChannelPositions(on guildId: GuildID, channelPositions: [[String: Any]],
                                            callback: (([DiscordGuildChannel]) -> ())? = nil) {
        guard let contentData = JSON.encodeJSONData(channelPositions) else { return }

        let requestCallback: DiscordRequestCallback = { data, response, error in
            guard case let .array(channels)? = JSON.jsonFromResponse(data: data, response: response) else {
                callback?([])

                return
            }

            callback?(Array(guildChannels(fromArray: channels as! [[String: Any]], guildID: guildId).values))
        }

        rateLimiter.executeRequest(endpoint: .guildChannels(guild: guildId),
                                   token: token,
                                   requestInfo: .patch(content: .json(contentData), extraHeaders: nil),
                                   callback: requestCallback)
    }

    /// Default implementation
    func modifyGuildMember(_ id: UserID, on guildId: GuildID,
                           options: [DiscordEndpoint.Options.ModifyMember],
                           reason: String? = nil,
                           callback: ((Bool) -> ())? = nil) {
        var patchParams: [String: Any] = [:]
        var extraHeaders = [DiscordHeader: String]()

        if let modifyReason = reason {
            extraHeaders[.auditReason] = modifyReason
        }

        for option in options {
            switch option {
            case let .channel(id):      patchParams["channel_id"] = id
            case let .deaf(deaf):       patchParams["deaf"] = deaf
            case let .mute(mute):       patchParams["mute"] = mute
            case let .nick(nick):       patchParams["nick"] = nick ?? ""
            case let .roles(roles):     patchParams["roles"] = roles.map({ $0.id })
            }
        }

        guard let contentData = JSON.encodeJSONData(patchParams) else { return }

        DefaultDiscordLogger.Logger.debug("Modifying guild member \(id) with options: \(patchParams) on \(guildId)",
                                          type: "DiscordEndpointGuild")

        rateLimiter.executeRequest(endpoint: .guildMember(guild: guildId, user: id),
                                   token: token,
                                   requestInfo: .patch(content: .json(contentData), extraHeaders: extraHeaders),
                                   callback: { _, response, _ in callback?(response?.statusCode == 204) })
    }

    /// Default implementation
    public func modifyGuildRole(_ role: DiscordRole,
                                on guildId: GuildID,
                                reason: String? = nil,
                                callback: ((DiscordRole?) -> ())? = nil) {
        guard let contentData = JSON.encodeJSONData(role) else { return }
        var extraHeaders = [DiscordHeader: String]()

        if let modifyReason = reason {
            extraHeaders[.auditReason] = modifyReason
        }

        let requestCallback: DiscordRequestCallback = { data, response, error in
            guard case let .object(role)? = JSON.jsonFromResponse(data: data, response: response) else {
                callback?(nil)

                return
            }

            callback?(DiscordRole(roleObject: role))
        }

        rateLimiter.executeRequest(endpoint: .guildRoles(guild: guildId),
                                   token: token,
                                   requestInfo: .patch(content: .json(contentData), extraHeaders: extraHeaders),
                                   callback: requestCallback)
    }

    /// Default implementation
    public func removeGuildBan(for userId: UserID,
                               on guildId: GuildID,
                               reason: String? = nil,
                               callback: ((Bool) -> ())? = nil) {
        DefaultDiscordLogger.Logger.log("Unbanning \(userId) on \(guildId)", type: "DiscordEndpointGuild")

        var extraHeaders = [DiscordHeader: String]()

        if let modifyReason = reason {
            extraHeaders[.auditReason] = modifyReason
        }

        rateLimiter.executeRequest(endpoint: .guildBanUser(guild: guildId, user: userId),
                                   token: token,
                                   requestInfo: .delete(content: nil, extraHeaders: extraHeaders),
                                   callback: { _, response, _ in callback?(response?.statusCode == 204) })
    }

    /// Default implementation.
    public func removeGuildMemberRole(_ roleId: RoleID,
                                      from userId: UserID,
                                      on guildId: GuildID,
                                      reason: String? = nil,
                                      callback: ((Bool) -> ())?) {
        var extraHeaders = [DiscordHeader: String]()

        if let modifyReason = reason {
            extraHeaders[.auditReason] = modifyReason
        }

        rateLimiter.executeRequest(endpoint: .guildMemberRole(guild: guildId, user: userId, role: roleId),
                                   token: token,
                                   requestInfo: .delete(content: nil, extraHeaders: extraHeaders),
                                   callback: { _, response, _ in callback?(response?.statusCode == 204) })
    }

    /// Default implementation
    public func removeGuildRole(_ roleId: RoleID,
                                on guildId: GuildID,
                                reason: String? = nil,
                                callback: ((DiscordRole?) -> ())? = nil) {
        var extraHeaders = [DiscordHeader: String]()

        if let modifyReason = reason {
            extraHeaders[.auditReason] = modifyReason
        }

        let requestCallback: DiscordRequestCallback = { data, response, error in
            guard case let .object(role)? = JSON.jsonFromResponse(data: data, response: response) else {
                callback?(nil)

                return
            }

            callback?(DiscordRole(roleObject: role))
        }

        rateLimiter.executeRequest(endpoint: .guildRole(guild: guildId, role: roleId),
                                   token: token,
                                   requestInfo: .delete(content: nil, extraHeaders: extraHeaders),
                                   callback: requestCallback)
    }
}
