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

public extension DiscordEndpointConsumer {
    /// Default implementation
    public func addGuildMemberRole(_ roleId: String, to userId: String, on guildId: String,
                                   callback: ((Bool) -> ())?) {
        var request = DiscordEndpoint.createRequest(with: token, for: .guildMemberRole, replacing: [
            "guild.id": guildId,
            "user.id": userId,
            "role.id": roleId
        ])

        request.httpMethod = "PUT"

        let rateLimiterKey = DiscordRateLimitKey(endpoint: .guildMemberRole, parameters: ["guild.id": guildId])

        rateLimiter.executeRequest(request, for: rateLimiterKey, callback: {data, response, error in
            callback?(response?.statusCode == 204)
        })
    }

    /// Default implementation
    public func createGuildChannel(on guildId: String, options: [DiscordEndpoint.Options.GuildCreateChannel],
                                   callback: ((DiscordGuildChannel?) -> ())? = nil) {
        var createJSON: [String: Any] = [:]

        for option in options {
            switch option {
            case let .bitrate(bps):
                createJSON["bitrate"] = bps
            case let .name(name):
                createJSON["name"] = name
            case let .permissionOverwrites(overwrites):
                createJSON["permission_overwrites"] = overwrites.map({ $0.json })
            case let .type(type):
                createJSON["type"] = type.rawValue
            case let .userLimit(limit):
                createJSON["user_limit"] = limit
            }
        }

        guard let contentData = JSON.encodeJSONData(createJSON) else { return }

        var request = DiscordEndpoint.createRequest(with: token, for: .guildChannels, replacing: [
            "guild.id": guildId
        ])

        request.httpMethod = "POST"
        request.httpBody = contentData
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(String(contentData.count), forHTTPHeaderField: "Content-Length")

        DefaultDiscordLogger.Logger.log("Creating guild channel on %@", type: "DiscordEndpointGuild", args: guildId)

        let rateLimiterKey = DiscordRateLimitKey(endpoint: .guildChannels, parameters: ["guild.id": guildId])

        rateLimiter.executeRequest(request, for: rateLimiterKey, callback: {data, response, error in
            guard case let .object(channel)? = JSON.jsonFromResponse(data: data, response: response) else {
                callback?(nil)

                return
            }

            callback?(DiscordGuildChannel(guildChannelObject: channel))
        })
    }

    /// Default implementation
    public func createGuildRole(on guildId: String, withOptions options: [DiscordEndpoint.Options.CreateRole] = [],
                                callback: @escaping (DiscordRole?) -> ()) {
        var roleData: [String: Any] = [:]

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

        DefaultDiscordLogger.Logger.log("Creating a new role on %@", type: "DiscordEndpointGuild", args: guildId)
        DefaultDiscordLogger.Logger.verbose("Role options %@", type: "DiscordEndpointGuild", args: roleData)

        guard let contentData = JSON.encodeJSONData(roleData) else { return callback(nil) }

        var request = DiscordEndpoint.createRequest(with: token, for: .guildRoles, replacing: ["guild.id": guildId])

        request.httpMethod = "POST"
        request.httpBody = contentData

        let rateLimiterKey = DiscordRateLimitKey(endpoint: .guildRoles, parameters: ["guild.id": guildId])

        rateLimiter.executeRequest(request, for: rateLimiterKey, callback: {data, response, error in
            guard case let .object(role)? = JSON.jsonFromResponse(data: data, response: response) else {
                callback(nil)

                return
            }

            callback(DiscordRole(roleObject: role))
        })
    }

    /// Default implementation
    public func deleteGuild(_ guildId: String, callback: ((DiscordGuild?) -> ())? = nil) {
        var request = DiscordEndpoint.createRequest(with: token, for: .guilds, replacing: [
            "guild.id": guildId,
        ])

        request.httpMethod = "DELETE"

        let rateLimiterKey = DiscordRateLimitKey(endpoint: .guilds, parameters: ["guild.id": guildId])

        rateLimiter.executeRequest(request, for: rateLimiterKey, callback: {data, response, error in
            guard case let .object(guild)? = JSON.jsonFromResponse(data: data, response: response) else {
                callback?(nil)

                return
            }

            callback?(DiscordGuild(guildObject: guild, client: nil))
        })
    }

    /// Default implementation
    public func getGuildBans(for guildId: String, callback: @escaping ([DiscordBan]) -> ()) {
        let request = DiscordEndpoint.createRequest(with: token, for: .guildBans, replacing: ["guild.id": guildId])
        let rateLimiterKey = DiscordRateLimitKey(endpoint: .guildBans, parameters: ["guild.id": guildId])

        rateLimiter.executeRequest(request, for: rateLimiterKey, callback: {data, response, error in
            guard case let .array(bans)? = JSON.jsonFromResponse(data: data, response: response) else {
                callback([])

                return
            }

            DefaultDiscordLogger.Logger.debug("Got guild bans %@", type: "DiscordEndpointGuild", args: bans)

            callback(DiscordBan.bansFromArray(bans as! [[String: Any]]))
        })
    }

    /// Default implementation
    public func getGuildChannels(_ guildId: String, callback: @escaping ([DiscordGuildChannel]) -> ()) {
        let request = DiscordEndpoint.createRequest(with: token, for: .guildChannels, replacing: ["guild.id": guildId])
        let rateLimiterKey = DiscordRateLimitKey(endpoint: .guildChannels, parameters: ["guild.id": guildId])

        rateLimiter.executeRequest(request, for: rateLimiterKey, callback: {data, response, error in
            guard case let .array(channels)? = JSON.jsonFromResponse(data: data, response: response) else {
                callback([])

                return
            }

            callback(DiscordGuildChannel.guildChannelsFromArray(channels as! [[String: Any]]).map({ $0.value }))
        })
    }

    /// Default implementation
    public func getGuildMember(by id: String, on guildId: String, callback: @escaping (DiscordGuildMember?) -> ()) {
        let request = DiscordEndpoint.createRequest(with: token, for: .guildMember, replacing: [
            "guild.id": guildId,
            "user.id": id
        ])
        let rateLimiterKey = DiscordRateLimitKey(endpoint: .guildMembers, parameters: ["guild.id": guildId])

        rateLimiter.executeRequest(request, for: rateLimiterKey, callback: {data, response, error in
            guard case let .object(member)? = JSON.jsonFromResponse(data: data, response: response) else {
                callback(nil)

                return
            }

            callback(DiscordGuildMember(guildMemberObject: member, guildId: guildId))
        })
    }

    /// Default implementation
    public func getGuildMembers(on guildId: String, options: [DiscordEndpoint.Options.GuildGetMembers],
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

        let request = DiscordEndpoint.createRequest(with: token, for: .guildMembers, replacing: ["guild.id": guildId],
                                                    getParams: getParams)
        let rateLimiterKey = DiscordRateLimitKey(endpoint: .guildMembers, parameters: ["guild.id": guildId])

        rateLimiter.executeRequest(request, for: rateLimiterKey, callback: {data, response, error in
            guard case let .array(members)? = JSON.jsonFromResponse(data: data, response: response) else {
                callback([])

                return
            }

            let guildMembers = DiscordGuildMember.guildMembersFromArray(members as! [[String: Any]],
                                                                        withGuildId: guildId, guild: nil)

            callback(guildMembers.map({ $0.1 }))
        })
    }

    /// Default implementation
    public func getGuildRoles(for guildId: String, callback: @escaping ([DiscordRole]) -> ()) {
        let request = DiscordEndpoint.createRequest(with: token, for: .guildRoles, replacing: ["guild.id": guildId])
        let rateLimiterKey = DiscordRateLimitKey(endpoint: .guildRoles, parameters: ["guild.id": guildId])

        rateLimiter.executeRequest(request, for: rateLimiterKey, callback: {data, response, error in
            guard case let .array(roles)? = JSON.jsonFromResponse(data: data, response: response) else {
                callback([])

                return
            }

            callback(DiscordRole.rolesFromArray(roles as! [[String: Any]]).map({ $0.value }))
        })
    }

    /// Default implementation
    public func guildBan(userId: String, on guildId: String, deleteMessageDays: Int = 7,
                         callback: ((Bool) -> ())? = nil) {
        guard let contentData = JSON.encodeJSONData(["delete-message-days": deleteMessageDays]) else { return }

        var request = DiscordEndpoint.createRequest(with: token, for: .guildBanUser, replacing: [
            "guild.id": guildId,
            "user.id": userId
        ])

        request.httpMethod = "PUT"
        request.httpBody = contentData
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(String(contentData.count), forHTTPHeaderField: "Content-Length")

        let rateLimiterKey = DiscordRateLimitKey(endpoint: .guildBans, parameters: ["guild.id": guildId])

        rateLimiter.executeRequest(request, for: rateLimiterKey, callback: {data, response, error in
            callback?(response?.statusCode == 204)
        })
    }

    /// Default implementation
    public func modifyGuild(_ guildId: String, options: [DiscordEndpoint.Options.ModifyGuild],
                            callback: ((DiscordGuild?) -> ())? = nil) {
        var modifyJSON: [String: Any] = [:]

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

        var request = DiscordEndpoint.createRequest(with: token, for: .guilds, replacing: [
            "guild.id": guildId
        ])

        request.httpMethod = "PATCH"
        request.httpBody = contentData
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(String(contentData.count), forHTTPHeaderField: "Content-Length")

        let rateLimiterKey = DiscordRateLimitKey(endpoint: .guilds, parameters: ["guild.id": guildId])

        rateLimiter.executeRequest(request, for: rateLimiterKey, callback: {data, response, error in
            guard case let .object(guild)? = JSON.jsonFromResponse(data: data, response: response) else {
                callback?(nil)

                return
            }

            callback?(DiscordGuild(guildObject: guild, client: nil))
        })
    }

    /// Default implementation
    public func modifyGuildChannelPositions(on guildId: String, channelPositions: [[String: Any]],
                                            callback: (([DiscordGuildChannel]) -> ())? = nil) {
        guard let contentData = JSON.encodeJSONData(channelPositions) else { return }

        var request = DiscordEndpoint.createRequest(with: token, for: .guildChannels, replacing: [
            "guild.id": guildId
        ])

        request.httpMethod = "PATCH"
        request.httpBody = contentData
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(String(contentData.count), forHTTPHeaderField: "Content-Length")

        let rateLimiterKey = DiscordRateLimitKey(endpoint: .guildChannels, parameters: ["guild.id": guildId])

        rateLimiter.executeRequest(request, for: rateLimiterKey, callback: {data, response, error in
            guard case let .array(channels)? = JSON.jsonFromResponse(data: data, response: response) else {
                callback?([])

                return
            }

            callback?(DiscordGuildChannel.guildChannelsFromArray(channels as! [[String: Any]]).map({ $0.value }))
        })
    }

    /// Default implementation
    func modifyGuildMember(_ id: String, on guildId: String, options: [DiscordEndpoint.Options.ModifyMember],
                           callback: ((Bool) -> ())? = nil) {
        var patchParams: [String: Any] = [:]

        for option in options {
            switch option {
            case let .channel(id):      patchParams["channel_id"] = id
            case let .deaf(deaf):       patchParams["deaf"] = deaf
            case let .mute(mute):       patchParams["mute"] = mute
            case let .nick(nick):       patchParams["nick"] = nick ?? ""
            case let .roles(roles):     patchParams["roles"] = roles.map({ $0.id })
            }
        }

        DefaultDiscordLogger.Logger.debug("Modifying guild member %@ with options: %@ on %@",
                                          type: "DiscordEndpointGuild",
                                          args: id, patchParams, guildId)

        guard let contentData = JSON.encodeJSONData(patchParams) else { return }

        var request = DiscordEndpoint.createRequest(with: token, for: .guildMember, replacing: [
            "guild.id": guildId,
            "user.id": id
        ])

        request.httpMethod = "PATCH"
        request.httpBody = contentData
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(String(contentData.count), forHTTPHeaderField: "Content-Length")

        let rateLimiterKey = DiscordRateLimitKey(endpoint: .guildMembers, parameters: ["guild.id": guildId])

        rateLimiter.executeRequest(request, for: rateLimiterKey, callback: {data, response, error in
            callback?(response?.statusCode == 204)
        })
    }

    /// Default implementation
    public func modifyGuildRole(_ role: DiscordRole, on guildId: String, callback: ((DiscordRole?) -> ())? = nil) {
        var request = DiscordEndpoint.createRequest(with: token, for: .guildRole, replacing: [
            "guild.id": guildId,
            "role.id": role.id
        ])

        guard let contentData = JSON.encodeJSONData(role.json) else { return }

        request.httpMethod = "PATCH"
        request.httpBody = contentData
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(String(contentData.count), forHTTPHeaderField: "Content-Length")

        let rateLimiterKey = DiscordRateLimitKey(endpoint: .guildRoles, parameters: ["guild.id": guildId])

        rateLimiter.executeRequest(request, for: rateLimiterKey, callback: {data, response, error in
            guard case let .object(role)? = JSON.jsonFromResponse(data: data, response: response) else {
                callback?(nil)

                return
            }

            callback?(DiscordRole(roleObject: role))
        })
    }

    /// Default implementation
    public func removeGuildBan(for userId: String, on guildId: String, callback: ((Bool) -> ())? = nil) {
        var request = DiscordEndpoint.createRequest(with: token, for: .guildBanUser, replacing: [
            "guild.id": guildId,
            "user.id": userId
        ])

        request.httpMethod = "DELETE"

        DefaultDiscordLogger.Logger.log("Unbanning %@ on %@", type: "DiscordEndpointGuild", args: userId, guildId)

        let rateLimiterKey = DiscordRateLimitKey(endpoint: .guildBans, parameters: ["guild.id": guildId])

        rateLimiter.executeRequest(request, for: rateLimiterKey, callback: {data, response, error in
            callback?(response?.statusCode == 204)
        })
    }

    /// Default implementation.
    public func removeGuildMemberRole(_ roleId: String, from userId: String, on guildId: String,
                                      callback: ((Bool) -> ())?) {
        var request = DiscordEndpoint.createRequest(with: token, for: .guildMemberRole, replacing: [
            "guild.id": guildId,
            "user.id": userId,
            "role.id": roleId
        ])

        request.httpMethod = "DELETE"

        let rateLimiterKey = DiscordRateLimitKey(endpoint: .guildMemberRole, parameters: ["guild.id": guildId])

        rateLimiter.executeRequest(request, for: rateLimiterKey, callback: {data, response, error in
            callback?(response?.statusCode == 204)
        })
    }

    /// Default implementation
    public func removeGuildRole(_ roleId: String, on guildId: String, callback: ((DiscordRole?) -> ())? = nil) {
        var request = DiscordEndpoint.createRequest(with: token, for: .guildRole, replacing: [
            "guild.id": guildId,
            "role.id": roleId
        ])

        request.httpMethod = "DELETE"

        let rateLimiterKey = DiscordRateLimitKey(endpoint: .guildRoles, parameters: ["guild.id": guildId])

        rateLimiter.executeRequest(request, for: rateLimiterKey, callback: {data, response, error in
            guard case let .object(role)? = JSON.jsonFromResponse(data: data, response: response) else {
                callback?(nil)

                return
            }

            callback?(DiscordRole(roleObject: role))
        })
    }
}
