// TODO Add guild member
// TODO Guild integrations
// TODO Guild pruning
// TODO Guild embeds
// TODO Guild batch modify roles
public extension DiscordEndpoint {
    // TODO create guild
    public static func deleteGuild(_ guildId: String, with token: String, isBot bot: Bool) {
        var request = createRequest(with: token, for: .guilds, replacing: [
            "guild.id": guildId,
            ], isBot: bot)

        request.httpMethod = "DELETE"

        let rateLimiterKey = DiscordRateLimitKey(endpoint: .guilds, parameters: ["guild.id": guildId])

        DiscordRateLimiter.executeRequest(request, for: rateLimiterKey, callback: {data, response, error in })
    }

    public static func modifyGuild(_ guildId: String, options: [DiscordEndpointOptions.ModifyGuild],
            with token: String, isBot bot: Bool) {
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

        guard let contentData = encodeJSON(modifyJSON)?.data(using: .utf8, allowLossyConversion: false) else {
            return
        }

        var request = createRequest(with: token, for: .guilds, replacing: [
            "guild.id": guildId
            ], isBot: bot)

        request.httpMethod = "PATCH"
        request.httpBody = contentData
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(String(contentData.count), forHTTPHeaderField: "Content-Length")

        let rateLimiterKey = DiscordRateLimitKey(endpoint: .guilds, parameters: ["guild.id": guildId])

        DiscordRateLimiter.executeRequest(request, for: rateLimiterKey, callback: {data, response, error in })
    }

    // Guild Channels
    public static func createGuildChannel(_ guildId: String, options: [DiscordEndpointOptions.GuildCreateChannel],
            with token: String, isBot bot: Bool) {
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

        guard let contentData = encodeJSON(createJSON)?.data(using: .utf8, allowLossyConversion: false) else {
            return
        }

        var request = createRequest(with: token, for: .guildChannels, replacing: [
            "guild.id": guildId
            ], isBot: bot)

        request.httpMethod = "POST"
        request.httpBody = contentData
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(String(contentData.count), forHTTPHeaderField: "Content-Length")

        let rateLimiterKey = DiscordRateLimitKey(endpoint: .guildChannels, parameters: ["guild.id": guildId])

        DiscordRateLimiter.executeRequest(request, for: rateLimiterKey, callback: {data, response, error in })
    }

    public static func getGuildChannels(_ guildId: String, with token: String, isBot bot: Bool,
            callback: @escaping ([DiscordGuildChannel]) -> Void) {
        var request = createRequest(with: token, for: .guildChannels, replacing: ["guild.id": guildId], isBot: bot)

        request.httpMethod = "GET"

        let rateLimiterKey = DiscordRateLimitKey(endpoint: .guildChannels, parameters: ["guild.id": guildId])

        DiscordRateLimiter.executeRequest(request, for: rateLimiterKey, callback: {data, response, error in
            guard let data = data, response?.statusCode == 200 else {
                callback([])

                return
            }

            guard let stringData = String(data: data, encoding: .utf8), let json = decodeJSON(stringData),
                case let .array(channels) = json else {
                    callback([])

                    return
            }

            callback(DiscordGuildChannel.guildChannelsFromArray(channels as! [[String: Any]]).map({ $0.value }))
        })
    }

    public static func modifyGuildChannelPosition(on guildId: String, channelId: String, position: Int,
            with token: String, isBot bot: Bool) {
        let modifyJSON: [String: Any] = [
            "id": channelId,
            "position": position
        ]

        guard let contentData = encodeJSON(modifyJSON)?.data(using: .utf8, allowLossyConversion: false) else {
            return
        }

        var request = createRequest(with: token, for: .guildChannels, replacing: [
            "guild.id": guildId
            ], isBot: bot)

        request.httpMethod = "PATCH"
        request.httpBody = contentData
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(String(contentData.count), forHTTPHeaderField: "Content-Length")

        let rateLimiterKey = DiscordRateLimitKey(endpoint: .guildChannels, parameters: ["guild.id": guildId])

        DiscordRateLimiter.executeRequest(request, for: rateLimiterKey, callback: {data, response, error in })
    }

    // Guild Members
    public static func getGuildMember(by id: String, on guildId: String, with token: String, isBot bot: Bool,
        callback: @escaping (DiscordGuildMember?) -> Void) {
        var request = createRequest(with: token, for: .guildMember, replacing: [
            "guild.id": guildId,
            "user.id": id
        ], isBot: bot)

        request.httpMethod = "GET"

        let rateLimiterKey = DiscordRateLimitKey(endpoint: .guildMembers, parameters: ["guild.id": guildId])

        DiscordRateLimiter.executeRequest(request, for: rateLimiterKey, callback: {data, response, error in
            guard let data = data, response?.statusCode == 200 else {
                callback(nil)

                return
            }

            guard let stringData = String(data: data, encoding: .utf8), let json = decodeJSON(stringData),
                case let .dictionary(member) = json else {
                    callback(nil)

                    return
            }

            callback(DiscordGuildMember(guildMemberObject: member))
        })
    }

    public static func getGuildMembers(on guildId: String, options: [DiscordEndpointOptions.GuildGetMembers],
            with token: String, isBot bot: Bool, callback: @escaping ([DiscordGuildMember]) -> Void) {
        var getParams: [String: String] = [:]

        for option in options {
            switch option {
            case let .after(highest):
                getParams["after"] = String(highest)
            case let .limit(number):
                getParams["limit"] = String(number)
            }
        }

        var request = createRequest(with: token, for: .guildMembers, replacing: ["guild.id": guildId], isBot: bot,
            getParams: getParams)

        request.httpMethod = "GET"

        let rateLimiterKey = DiscordRateLimitKey(endpoint: .guildMembers, parameters: ["guild.id": guildId])

        DiscordRateLimiter.executeRequest(request, for: rateLimiterKey, callback: {data, response, error in
            guard let data = data, response?.statusCode == 200 else {
                callback([])

                return
            }

            guard let stringData = String(data: data, encoding: .utf8), let json = decodeJSON(stringData),
                case let .array(members) = json else {
                    callback([])

                    return
            }

            callback(DiscordGuildMember.guildMembersFromArray(members as! [[String: Any]]).map({ $0.value }))
        })
    }

    // Guild Bans
    public static func getGuildBans(for guildId: String, with token: String, isBot bot: Bool,
            callback: @escaping ([DiscordUser]) -> Void) {
        var request = createRequest(with: token, for: .guildBans, replacing: ["guild.id": guildId], isBot: bot)

        request.httpMethod = "GET"

        let rateLimiterKey = DiscordRateLimitKey(endpoint: .guildBans, parameters: ["guild.id": guildId])

        DiscordRateLimiter.executeRequest(request, for: rateLimiterKey, callback: {data, response, error in
            guard let data = data, response?.statusCode == 200 else {
                callback([])

                return
            }

            guard let stringData = String(data: data, encoding: .utf8), let json = decodeJSON(stringData),
                case let .array(users) = json else {
                    callback([])

                    return
            }

            callback(DiscordUser.usersFromArray(users as! [[String: Any]]))
        })
    }

    public static func guildBan(userId: String, on guildId: String, deleteMessageDays: Int, with token: String,
            isBot bot: Bool) {
        let banJSON = ["delete-message-days": deleteMessageDays]

        var request = createRequest(with: token, for: .guildBanUser, replacing: [
            "guild.id": guildId,
            "user.id": userId
            ], isBot: bot)

        guard let contentData = encodeJSON(banJSON)?.data(using: .utf8, allowLossyConversion: false) else {
            return
        }

        request.httpMethod = "PUT"
        request.httpBody = contentData
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(String(contentData.count), forHTTPHeaderField: "Content-Length")

        let rateLimiterKey = DiscordRateLimitKey(endpoint: .guildBans, parameters: ["guild.id": guildId])

        DiscordRateLimiter.executeRequest(request, for: rateLimiterKey, callback: {data, response, error in })
    }

    public static func removeGuildBan(for userId: String, on guildId: String, with token: String, isBot bot: Bool) {
        var request = createRequest(with: token, for: .guildBanUser, replacing: [
            "guild.id": guildId,
            "user.id": userId
            ], isBot: bot)

        request.httpMethod = "DELETE"

        let rateLimiterKey = DiscordRateLimitKey(endpoint: .guildBans, parameters: ["guild.id": guildId])

        DiscordRateLimiter.executeRequest(request, for: rateLimiterKey, callback: {data, response, error in })
    }

    // Guild Roles
    public static func createGuildRole(on guildId: String, with token: String, isBot bot: Bool,
            callback: @escaping (DiscordRole?) -> Void) {
          var request = createRequest(with: token, for: .guildRoles, replacing: ["guild.id": guildId], isBot: bot)

          request.httpMethod = "POST"

          let rateLimiterKey = DiscordRateLimitKey(endpoint: .guildRoles, parameters: ["guild.id": guildId])

          DiscordRateLimiter.executeRequest(request, for: rateLimiterKey, callback: {data, response, error in
              guard let data = data, response?.statusCode == 200 || response?.statusCode == 201 else {
                  callback(nil)

                  return
              }

              guard let stringData = String(data: data, encoding: .utf8), let json = decodeJSON(stringData),
                  case let .dictionary(role) = json else {
                      callback(nil)

                      return
              }

              callback(DiscordRole(roleObject: role))
          })
    }

    public static func getGuildRoles(for guildId: String, with token: String, isBot bot: Bool,
            callback: @escaping ([DiscordRole]) -> Void) {
          var request = createRequest(with: token, for: .guildRoles, replacing: ["guild.id": guildId], isBot: bot)

          request.httpMethod = "GET"

          let rateLimiterKey = DiscordRateLimitKey(endpoint: .guildRoles, parameters: ["guild.id": guildId])

          DiscordRateLimiter.executeRequest(request, for: rateLimiterKey, callback: {data, response, error in
              guard let data = data, response?.statusCode == 200 else {
                  callback([])

                  return
              }

              guard let stringData = String(data: data, encoding: .utf8), let json = decodeJSON(stringData),
                  case let .array(roles) = json else {
                      callback([])

                      return
              }

              callback(DiscordRole.rolesFromArray(roles as! [[String: Any]]).map({ $0.value }))
          })
    }

    public static func modifyGuildRole(_ role: DiscordRole, on guildId: String, with token: String, isBot bot: Bool) {
        let roleJSON = role.json

        var request = createRequest(with: token, for: .guildRole, replacing: [
            "guild.id": guildId,
            "role.id": role.id
            ], isBot: bot)

        guard let contentData = encodeJSON(roleJSON)?.data(using: .utf8, allowLossyConversion: false) else {
            return
        }

        request.httpMethod = "PATCH"
        request.httpBody = contentData
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(String(contentData.count), forHTTPHeaderField: "Content-Length")

        let rateLimiterKey = DiscordRateLimitKey(endpoint: .guildRoles, parameters: ["guild.id": guildId])

        DiscordRateLimiter.executeRequest(request, for: rateLimiterKey, callback: {data, response, error in })
    }

    public static func removeGuildRole(_ roleId: String, on guildId: String, with token: String, isBot bot: Bool) {
        var request = createRequest(with: token, for: .guildRole, replacing: [
            "guild.id": guildId,
            "role.id": roleId
            ], isBot: bot)

        request.httpMethod = "DELETE"

        let rateLimiterKey = DiscordRateLimitKey(endpoint: .guildRoles, parameters: ["guild.id": guildId])

        DiscordRateLimiter.executeRequest(request, for: rateLimiterKey, callback: {data, response, error in })
    }
}
