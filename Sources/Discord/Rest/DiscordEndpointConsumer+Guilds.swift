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
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import Logging

fileprivate let logger = Logger(label: "DiscordEndpointGuild")

public extension DiscordEndpointConsumer where Self: DiscordUserActor {
    /// Default implementation
    func addGuildMemberRole(_ roleId: RoleID,
                                   to userId: UserID,
                                   on guildId: GuildID,
                                   reason: String? = nil,
                                   callback: ((Bool, HTTPURLResponse?) -> ())?) {
        var extraHeaders = [DiscordHeader: String]()

        if let modifyReason = reason {
            extraHeaders[.auditReason] = modifyReason
        }

        rateLimiter.executeRequest(endpoint: .guildMemberRole(guild: guildId, user: userId, role: roleId),
                                   token: token,
                                   requestInfo: .put(content: nil, extraHeaders: extraHeaders),
                                   callback: { _, response, _ in callback?(response?.statusCode == 204, response) })
    }

    /// Default implementation
    func createGuildChannel(on guildId: GuildID,
                                   options: [DiscordEndpoint.Options.GuildCreateChannel],
                                   reason: String? = nil,
                                   callback: ((DiscordChannel?, HTTPURLResponse?) -> ())? = nil) {
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

        guard let contentData = try? DiscordJSON.encode(GenericEncodableDictionary(createJSON)) else { return }

        let requestCallback: DiscordRequestCallback = { data, response, error in
            guard let channel: DiscordChannel = DiscordJSON.decodeResponse(data: data, response: response) else {
                callback?(nil, response)

                return
            }

            callback?(channel, response)
        }

        rateLimiter.executeRequest(endpoint: .guildChannels(guild: guildId),
                                   token: token,
                                   requestInfo: .post(content: .json(contentData), extraHeaders: extraHeaders),
                                   callback: requestCallback)
    }

    /// Default implementation
    func createGuildRole(on guildId: GuildID,
                                withOptions options: [DiscordEndpoint.Options.CreateRole] = [],
                                reason: String? = nil,
                                callback: @escaping (DiscordRole?, HTTPURLResponse?) -> ()) {
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
                roleData["permissions"] = permissions.rawValue.description
            }
        }

        logger.info("Creating a new role on \(guildId)")
        logger.debug("(verbose) Role options \(roleData)")

        guard let contentData = try? DiscordJSON.encode(GenericEncodableDictionary(roleData)) else { return callback(nil, nil) }

        let requestCallback: DiscordRequestCallback = { data, response, error in
            guard let role: DiscordRole = DiscordJSON.decodeResponse(data: data, response: response) else {
                callback(nil, response)

                return
            }

            callback(role, response)
        }

        rateLimiter.executeRequest(endpoint: .guildRoles(guild: guildId),
                                   token: token,
                                   requestInfo: .post(content: .json(contentData), extraHeaders: extraHeaders),
                                   callback: requestCallback)
    }

    /// Default implementation
    func deleteGuild(_ guildId: GuildID,
                            callback: ((DiscordGuild?, HTTPURLResponse?) -> ())? = nil) {
        let requestCallback: DiscordRequestCallback = { data, response, error in
            guard let guild: DiscordGuild = DiscordJSON.decodeResponse(data: data, response: response) else {
                callback?(nil, response)

                return
            }

            callback?(guild, response)
        }

        rateLimiter.executeRequest(endpoint: .guilds(id: guildId),
                                   token: token,
                                   requestInfo: .delete(content: nil, extraHeaders: nil),
                                   callback: requestCallback)
    }

    /// Default implementation.
    func getGuildAuditLog(for guildId: GuildID,
                          withOptions options: [DiscordEndpoint.Options.AuditLog],
                          callback: @escaping (DiscordAuditLog?, HTTPURLResponse?) -> ()) {
        logger.debug("Getting audit log for \(guildId)")

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
            guard let log: DiscordAuditLog = DiscordJSON.decodeResponse(data: data, response: response) else {
                callback(nil, response)

                return
            }

            logger.debug("Got audit log for \(guildId)")

            callback(log, response)
        }

        rateLimiter.executeRequest(endpoint: .guildAuditLog(id: guildId),
                                   token: token,
                                   requestInfo: .get(params: getParams, extraHeaders: nil),
                                   callback: requestCallback)
    }

    /// Default implementation
    func getGuildBans(for guildId: GuildID,
                             callback: @escaping ([DiscordBan], HTTPURLResponse?) -> ()) {
        let requestCallback: DiscordRequestCallback = { data, response, error in
            guard let bans: [DiscordBan] = DiscordJSON.decodeResponse(data: data, response: response) else {
                callback([], response)

                return
            }

            logger.debug("Got guild bans \(bans)")
            callback(bans, response)
        }

        rateLimiter.executeRequest(endpoint: .guildBans(guild: guildId),
                                   token: token,
                                   requestInfo: .get(params: nil, extraHeaders: nil),
                                   callback: requestCallback)
    }

    /// Default implementation
    func getGuildChannels(_ guildId: GuildID,
                                 callback: @escaping ([DiscordChannel], HTTPURLResponse?) -> ()) {
        let requestCallback: DiscordRequestCallback = { data, response, error in
            guard let channels: [DiscordChannel] = DiscordJSON.decodeResponse(data: data, response: response) else {
                callback([], response)

                return
            }

            callback(channels, response)
        }

        rateLimiter.executeRequest(endpoint: .guildChannels(guild: guildId),
                                   token: token,
                                   requestInfo: .get(params: nil, extraHeaders: nil),
                                   callback: requestCallback)
    }

    /// Default implementation
    func getGuildMember(by id: UserID,
                               on guildId: GuildID,
                               callback: @escaping (DiscordGuildMember?, HTTPURLResponse?) -> ()) {
        let requestCallback: DiscordRequestCallback = { data, response, error in
            guard let member: DiscordGuildMember = DiscordJSON.decodeResponse(data: data, response: response) else {
                callback(nil, response)

                return
            }

            callback(member, response)
        }

        rateLimiter.executeRequest(endpoint: .guildMember(guild: guildId, user: id),
                                   token: token,
                                   requestInfo: .get(params: nil, extraHeaders: nil),
                                   callback: requestCallback)
    }

    /// Default implementation
    func getGuildMembers(on guildId: GuildID,
                                options: [DiscordEndpoint.Options.GuildGetMembers],
                                callback: @escaping ([DiscordGuildMember], HTTPURLResponse?) -> ()) {
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
            guard let members: [DiscordGuildMember] = DiscordJSON.decodeResponse(data: data, response: response) else {
                callback([], response)

                return
            }

            callback(members, response)
        }

        rateLimiter.executeRequest(endpoint: .guildMembers(guild: guildId),
                                   token: token,
                                   requestInfo: .get(params: getParams, extraHeaders: nil),
                                   callback: requestCallback)
    }

    /// Default implementation
    func getGuildRoles(for guildId: GuildID,
                              callback: @escaping ([DiscordRole], HTTPURLResponse?) -> ()) {
        let requestCallback: DiscordRequestCallback = { data, response, error in
            guard let roles: [DiscordRole] = DiscordJSON.decodeResponse(data: data, response: response) else {
                callback([], response)

                return
            }

            callback(roles, response)
        }

        rateLimiter.executeRequest(endpoint: .guildRoles(guild: guildId),
                                   token: token,
                                   requestInfo: .get(params: nil, extraHeaders: nil),
                                   callback: requestCallback)
    }

    /// Default implementation
    func guildBan(userId: UserID,
                         on guildId: GuildID,
                         deleteMessageDays: Int = 7,
                         reason: String? = nil,
                         callback: ((Bool, HTTPURLResponse?) -> ())? = nil) {
        guard let contentData = try? DiscordJSON.encode(["delete-message-days": deleteMessageDays]) else { return }
        var extraHeaders = [DiscordHeader: String]()

        if let modifyReason = reason {
            extraHeaders[.auditReason] = modifyReason
        }

        rateLimiter.executeRequest(endpoint: .guildBanUser(guild: guildId, user: userId),
                                   token: token,
                                   requestInfo: .put(content: .json(contentData), extraHeaders: extraHeaders),
                                   callback: { _, response, _ in callback?(response?.statusCode == 204, response) })
    }

    /// Default implementation
    func modifyGuild(_ guildId: GuildID,
                            options: DiscordEndpoint.Options.ModifyGuild,
                            reason: String? = nil,
                            callback: ((DiscordGuild?, HTTPURLResponse?) -> ())? = nil) {
        var extraHeaders = [DiscordHeader: String]()

        if let modifyReason = reason {
            extraHeaders[.auditReason] = modifyReason
        }

        guard let contentData = try? DiscordJSON.encode(options) else { return }

        let requestCallback: DiscordRequestCallback = { data, response, error in
            guard let guild: DiscordGuild = DiscordJSON.decodeResponse(data: data, response: response) else {
                callback?(nil, response)

                return
            }

            callback?(guild, response)
        }

        rateLimiter.executeRequest(endpoint: .guilds(id: guildId),
                                   token: token,
                                   requestInfo: .patch(content: .json(contentData), extraHeaders: extraHeaders),
                                   callback: requestCallback)
    }

    /// Default implementation
    func modifyGuildChannelPositions(on guildId: GuildID,
                                            channelPositions: [[String: Any]],
                                            callback: (([DiscordChannel], HTTPURLResponse?) -> ())? = nil) {
        guard let contentData = try? DiscordJSON.encode(GenericEncodableArray(channelPositions)) else { return }

        let requestCallback: DiscordRequestCallback = { data, response, error in
            guard let channels: [DiscordChannel] = DiscordJSON.decodeResponse(data: data, response: response) else {
                callback?([], response)

                return
            }

            callback?(channels, response)
        }

        rateLimiter.executeRequest(endpoint: .guildChannels(guild: guildId),
                                   token: token,
                                   requestInfo: .patch(content: .json(contentData), extraHeaders: nil),
                                   callback: requestCallback)
    }

    /// Default implementation
    func modifyGuildMember(_ id: UserID, on guildId: GuildID,
                           options: DiscordEndpoint.Options.ModifyMember,
                           reason: String? = nil,
                           callback: ((Bool, HTTPURLResponse?) -> ())? = nil) {
        var extraHeaders = [DiscordHeader: String]()

        if let modifyReason = reason {
            extraHeaders[.auditReason] = modifyReason
        }

        guard let contentData = try? DiscordJSON.encode(options) else { return }

        logger.debug("Modifying guild member \(id) with options: \(options) on \(guildId)")

        rateLimiter.executeRequest(endpoint: .guildMember(guild: guildId, user: id),
                                   token: token,
                                   requestInfo: .patch(content: .json(contentData), extraHeaders: extraHeaders),
                                   callback: { _, response, _ in callback?(response?.statusCode == 204, response) })
    }

    /// Default implementation
    func modifyGuildRole(_ role: DiscordRole,
                                on guildId: GuildID,
                                reason: String? = nil,
                                callback: ((DiscordRole?, HTTPURLResponse?) -> ())? = nil) {
        guard let contentData = try? DiscordJSON.encode(role) else { return }
        var extraHeaders = [DiscordHeader: String]()

        if let modifyReason = reason {
            extraHeaders[.auditReason] = modifyReason
        }

        let requestCallback: DiscordRequestCallback = { data, response, error in
            guard let role: DiscordRole = DiscordJSON.decodeResponse(data: data, response: response) else {
                callback?(nil, response)

                return
            }

            callback?(role, response)
        }

        rateLimiter.executeRequest(endpoint: .guildRoles(guild: guildId),
                                   token: token,
                                   requestInfo: .patch(content: .json(contentData), extraHeaders: extraHeaders),
                                   callback: requestCallback)
    }

    /// Default implementation
    func removeGuildBan(for userId: UserID,
                               on guildId: GuildID,
                               reason: String? = nil,
                               callback: ((Bool, HTTPURLResponse?) -> ())? = nil) {
        logger.info("Unbanning \(userId) on \(guildId)")

        var extraHeaders = [DiscordHeader: String]()

        if let modifyReason = reason {
            extraHeaders[.auditReason] = modifyReason
        }

        rateLimiter.executeRequest(endpoint: .guildBanUser(guild: guildId, user: userId),
                                   token: token,
                                   requestInfo: .delete(content: nil, extraHeaders: extraHeaders),
                                   callback: { _, response, _ in callback?(response?.statusCode == 204, response) })
    }

    /// Default implementation.
    func removeGuildMemberRole(_ roleId: RoleID,
                                      from userId: UserID,
                                      on guildId: GuildID,
                                      reason: String? = nil,
                                      callback: ((Bool, HTTPURLResponse?) -> ())?) {
        var extraHeaders = [DiscordHeader: String]()

        if let modifyReason = reason {
            extraHeaders[.auditReason] = modifyReason
        }

        rateLimiter.executeRequest(endpoint: .guildMemberRole(guild: guildId, user: userId, role: roleId),
                                   token: token,
                                   requestInfo: .delete(content: nil, extraHeaders: extraHeaders),
                                   callback: { _, response, _ in callback?(response?.statusCode == 204, response) })
    }

    /// Default implementation
    func removeGuildRole(_ roleId: RoleID,
                                on guildId: GuildID,
                                reason: String? = nil,
                                callback: ((DiscordRole?, HTTPURLResponse?) -> ())? = nil) {
        var extraHeaders = [DiscordHeader: String]()

        if let modifyReason = reason {
            extraHeaders[.auditReason] = modifyReason
        }

        let requestCallback: DiscordRequestCallback = { data, response, error in
            guard let role: DiscordRole = DiscordJSON.decodeResponse(data: data, response: response) else {
                callback?(nil, response)

                return
            }

            callback?(role, response)
        }

        rateLimiter.executeRequest(endpoint: .guildRole(guild: guildId, role: roleId),
                                   token: token,
                                   requestInfo: .delete(content: nil, extraHeaders: extraHeaders),
                                   callback: requestCallback)
    }
}
