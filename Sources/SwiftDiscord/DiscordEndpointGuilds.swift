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

// TODO Add guild member
// TODO Guild integrations
// TODO Guild pruning
// TODO Guild embeds
// TODO Guild batch modify roles
public extension DiscordEndpoint {
    // MARK: Guilds

    // TODO create guild

    /**
        Deletes the specified guild.

        - parameter guildId: The snowflake id of the guild
        - parameter with: The token to authenticate to Discord with
        - parameter callback: An optional callback containing the deleted guild, if successful.
    */
    public static func deleteGuild(_ guildId: String, with token: DiscordToken, callback: ((DiscordGuild?) -> Void)?) {
        var request = createRequest(with: token, for: .guilds, replacing: [
            "guild.id": guildId,
        ])

        request.httpMethod = "DELETE"

        let rateLimiterKey = DiscordRateLimitKey(endpoint: .guilds, parameters: ["guild.id": guildId])

        DiscordRateLimiter.executeRequest(request, for: rateLimiterKey, callback: {data, response, error in
            guard case let .object(guild)? = self.jsonFromResponse(data: data, response: response) else {
                callback?(nil)

                return
            }

            callback?(DiscordGuild(guildObject: guild, client: nil))
        })
    }

    /**
        Modifies the specified guild.

        - parameter guildId: The snowflake id of the guild
        - parameter options: An array of `DiscordEndpointOptions.ModifyGuild` options
        - parameter with: The token to authenticate to Discord with
        - parameter callback: An optional callback containing the modified guild, if successful.
    */
    public static func modifyGuild(_ guildId: String, options: [DiscordEndpointOptions.ModifyGuild],
            with token: DiscordToken, callback: ((DiscordGuild?) -> Void)?) {
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
        ])

        request.httpMethod = "PATCH"
        request.httpBody = contentData
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(String(contentData.count), forHTTPHeaderField: "Content-Length")

        let rateLimiterKey = DiscordRateLimitKey(endpoint: .guilds, parameters: ["guild.id": guildId])

        DiscordRateLimiter.executeRequest(request, for: rateLimiterKey, callback: {data, response, error in
            guard case let .object(guild)? = self.jsonFromResponse(data: data, response: response) else {
                callback?(nil)

                return
            }

            callback?(DiscordGuild(guildObject: guild, client: nil))
        })
    }

    // Guild Channels

    /**
        Creates a guild channel.

        - parameter guildId: The snowflake id of the guild
        - parameter options: An array of `DiscordEndpointOptions.GuildCreateChannel` options
        - parameter with: The token to authenticate to Discord with
        - parameter callback: An optional callback containing the new channel, if successful.

    */
    public static func createGuildChannel(_ guildId: String, options: [DiscordEndpointOptions.GuildCreateChannel],
            with token: DiscordToken, callback: ((DiscordGuildChannel?) -> Void)?) {
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
        ])

        request.httpMethod = "POST"
        request.httpBody = contentData
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(String(contentData.count), forHTTPHeaderField: "Content-Length")

        DefaultDiscordLogger.Logger.log("Creating guild channel on %@", type: "DiscordEndpointGuild", args: guildId)

        let rateLimiterKey = DiscordRateLimitKey(endpoint: .guildChannels, parameters: ["guild.id": guildId])

        DiscordRateLimiter.executeRequest(request, for: rateLimiterKey, callback: {data, response, error in
            guard case let .object(channel)? = self.jsonFromResponse(data: data, response: response) else {
                callback?(nil)

                return
            }

            callback?(DiscordGuildChannel(guildChannelObject: channel))
        })
    }

    /**
        Gets the channels on a guild.

        - parameter guildId: The snowflake id of the guild
        - parameter with: The token to authenticate to Discord with
        - parameter callback: The callback function, taking an array of `DiscordGuildChannel`
    */
    public static func getGuildChannels(_ guildId: String, with token: DiscordToken,
            callback: @escaping ([DiscordGuildChannel]) -> Void) {
        var request = createRequest(with: token, for: .guildChannels, replacing: ["guild.id": guildId])

        request.httpMethod = "GET"

        let rateLimiterKey = DiscordRateLimitKey(endpoint: .guildChannels, parameters: ["guild.id": guildId])

        DiscordRateLimiter.executeRequest(request, for: rateLimiterKey, callback: {data, response, error in
            guard case let .array(channels)? = self.jsonFromResponse(data: data, response: response) else {
                callback([])

                return
            }

            callback(DiscordGuildChannel.guildChannelsFromArray(channels as! [[String: Any]]).map({ $0.value }))
        })
    }

    /**
        Modifies the positions of channels.

        - parameter on: The snowflake id of the guild
        - parameter channelPositions: An array of channels that should be reordered. Should contain a dictionary
                                      in the form `["id": channelId, "position": position]`
        - parameter with: The token to authenticate to Discord with
        - parameter callback: An optional callback containing the modified channels, if successful.
    */
    public static func modifyGuildChannelPositions(on guildId: String, channelPositions: [[String: Any]],
            with token: DiscordToken, callback: (([DiscordGuildChannel]) -> Void)?) {
        guard let contentData = encodeJSON(channelPositions)?.data(using: .utf8, allowLossyConversion: false) else {
            return
        }

        var request = createRequest(with: token, for: .guildChannels, replacing: [
            "guild.id": guildId
        ])

        request.httpMethod = "PATCH"
        request.httpBody = contentData
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(String(contentData.count), forHTTPHeaderField: "Content-Length")

        let rateLimiterKey = DiscordRateLimitKey(endpoint: .guildChannels, parameters: ["guild.id": guildId])

        DiscordRateLimiter.executeRequest(request, for: rateLimiterKey, callback: {data, response, error in
            guard case let .array(channels)? = self.jsonFromResponse(data: data, response: response) else {
                callback?([])

                return
            }

            callback?(DiscordGuildChannel.guildChannelsFromArray(channels as! [[String: Any]]).map({ $0.value }))
        })
    }

    // Guild Members

    /**
        Adds a role to a guild member.

        - parameter roleId: The id of the role to add.
        - parameter to: The id of the member to add this role to.
        - parameter on: The id of the guild this member is on.
        - parameter with: The token to authenticate to Discord with.
        - parameter callback: An optional callback indicating whether the role was added successfully.
    */
    public static func addGuildMemberRole(_ roleId: String, to userId: String, on guildId: String,
            with token: DiscordToken, callback: ((Bool) -> Void)?) {
        var request = createRequest(with: token, for: .guildMemberRole, replacing: [
            "guild.id": guildId,
            "user.id": userId,
            "role.id": roleId
        ])

        request.httpMethod = "PUT"

        let rateLimiterKey = DiscordRateLimitKey(endpoint: .guildMemberRole, parameters: ["guild.id": guildId])

        DiscordRateLimiter.executeRequest(request, for: rateLimiterKey, callback: {data, response, error in
           callback?(response?.statusCode == 204)
        })
    }

    /**
        Gets the specified guild member.

        - parameter by: The snowflake id of the member
        - parameter on: The snowflake id of the guild
        - parameter with: The token to authenticate to Discord with
        - parameter callback: The callback function containing an optional `DiscordGuildMember`
    */
    public static func getGuildMember(by id: String, on guildId: String, with token: DiscordToken,
        callback: @escaping (DiscordGuildMember?) -> Void) {
        var request = createRequest(with: token, for: .guildMember, replacing: [
            "guild.id": guildId,
            "user.id": id
        ])

        request.httpMethod = "GET"

        let rateLimiterKey = DiscordRateLimitKey(endpoint: .guildMembers, parameters: ["guild.id": guildId])

        DiscordRateLimiter.executeRequest(request, for: rateLimiterKey, callback: {data, response, error in
            guard case let .object(member)? = self.jsonFromResponse(data: data, response: response) else {
                callback(nil)

                return
            }

            callback(DiscordGuildMember(guildMemberObject: member, guildId: guildId))
        })
    }

    /**
        Gets the members on a guild.

        - parameter on: The snowflake id of the guild
        - parameter options: An array of `DiscordEndpointOptions.GuildGetMembers` options
        - parameter with: The token to authenticate to Discord with
        - parameter callback: The callback function, taking an array of `DiscordGuildMember`
    */
    public static func getGuildMembers(on guildId: String, options: [DiscordEndpointOptions.GuildGetMembers],
            with token: DiscordToken, callback: @escaping ([DiscordGuildMember]) -> Void) {
        var getParams: [String: String] = [:]

        for option in options {
            switch option {
            case let .after(highest):
                getParams["after"] = String(highest)
            case let .limit(number):
                getParams["limit"] = String(number)
            }
        }

        var request = createRequest(with: token, for: .guildMembers, replacing: ["guild.id": guildId],
            getParams: getParams)

        request.httpMethod = "GET"

        let rateLimiterKey = DiscordRateLimitKey(endpoint: .guildMembers, parameters: ["guild.id": guildId])

        DiscordRateLimiter.executeRequest(request, for: rateLimiterKey, callback: {data, response, error in
            guard case let .array(members)? = self.jsonFromResponse(data: data, response: response) else {
                callback([])

                return
            }

            let guildMembers = DiscordGuildMember.guildMembersFromArray(members as! [[String: Any]],
                withGuildId: guildId)

            callback(guildMembers.map({ $0.1 }))
        })
    }

    // Guild Bans

    /**
        Gets the bans on a guild.

        - parameter for: The snowflake id of the guild
        - parameter with: The token to authenticate to Discord with
        - parameter callback: The callback function, taking an array of `DiscordBan`
    */
    public static func getGuildBans(for guildId: String, with token: DiscordToken,
            callback: @escaping ([DiscordBan]) -> Void) {
        var request = createRequest(with: token, for: .guildBans, replacing: ["guild.id": guildId])

        request.httpMethod = "GET"

        let rateLimiterKey = DiscordRateLimitKey(endpoint: .guildBans, parameters: ["guild.id": guildId])

        DiscordRateLimiter.executeRequest(request, for: rateLimiterKey, callback: {data, response, error in
            guard case let .array(bans)? = self.jsonFromResponse(data: data, response: response) else {
                callback([])

                return
            }

            DefaultDiscordLogger.Logger.debug("Got guild bans %@", type: "DiscordEndpointGuild", args: bans)

            callback(DiscordBan.bansFromArray(bans as! [[String: Any]]))
        })
    }

    /**
        Creates a guild ban.

        - parameter userId: The snowflake id of the user
        - parameter on: The snowflake id of the guild
        - parameter deleteMessageDays: The number of days to delete this user's messages
        - parameter with: The token to authenticate to Discord with
        - parameter callback: An optional callback indicating whether the ban was successful.
    */
    public static func guildBan(userId: String, on guildId: String, deleteMessageDays: Int, with token: DiscordToken,
            callback: ((Bool) -> Void)?) {
        let banJSON = ["delete-message-days": deleteMessageDays]

        var request = createRequest(with: token, for: .guildBanUser, replacing: [
            "guild.id": guildId,
            "user.id": userId
        ])

        guard let contentData = encodeJSON(banJSON)?.data(using: .utf8, allowLossyConversion: false) else {
            return
        }

        request.httpMethod = "PUT"
        request.httpBody = contentData
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(String(contentData.count), forHTTPHeaderField: "Content-Length")

        let rateLimiterKey = DiscordRateLimitKey(endpoint: .guildBans, parameters: ["guild.id": guildId])

        DiscordRateLimiter.executeRequest(request, for: rateLimiterKey, callback: {data, response, error in
            callback?(response?.statusCode == 204)
        })
    }

    /**
        Removes a guild ban.

        - parameter for: The snowflake id of the user
        - parameter on: The snowflake id of the guild
        - parameter with: The token to authenticate to Discord with
        - parameter callback: An optional callback indicating whether the ban was successfully removed.
    */
    public static func removeGuildBan(for userId: String, on guildId: String, with token: DiscordToken,
            callback: ((Bool) -> Void)?) {
        var request = createRequest(with: token, for: .guildBanUser, replacing: [
            "guild.id": guildId,
            "user.id": userId
        ])

        request.httpMethod = "DELETE"

        DefaultDiscordLogger.Logger.log("Unbanning %@ on %@", type: "DiscordEndpointGuild", args: userId, guildId)

        let rateLimiterKey = DiscordRateLimitKey(endpoint: .guildBans, parameters: ["guild.id": guildId])

        DiscordRateLimiter.executeRequest(request, for: rateLimiterKey, callback: {data, response, error in
            callback?(response?.statusCode == 204)
        })
    }

    // Guild Roles

    /**
        Creates a role on a guild.

        - parameter on: The snowflake id of the guild
        - parameter with: The token to authenticate to Discord with
        - parameter callback: The callback function, taking an optional `DiscordRole`
    */
    public static func createGuildRole(on guildId: String, with token: DiscordToken,
            callback: @escaping (DiscordRole?) -> Void) {
        var request = createRequest(with: token, for: .guildRoles, replacing: ["guild.id": guildId])

        request.httpMethod = "POST"

        let rateLimiterKey = DiscordRateLimitKey(endpoint: .guildRoles, parameters: ["guild.id": guildId])

        DiscordRateLimiter.executeRequest(request, for: rateLimiterKey, callback: {data, response, error in
            guard case let .object(role)? = self.jsonFromResponse(data: data, response: response) else {
                callback(nil)

                return
            }

            callback(DiscordRole(roleObject: role))
        })
    }

    /**
        Gets the roles on a guild.

        - parameter for: The snowflake id of the guild
        - parameter with: The token to authenticate to Discord with
        - parameter callback: The callback function, taking an array of `DiscordRole`
    */
    public static func getGuildRoles(for guildId: String, with token: DiscordToken,
            callback: @escaping ([DiscordRole]) -> Void) {
        var request = createRequest(with: token, for: .guildRoles, replacing: ["guild.id": guildId])

        request.httpMethod = "GET"

        let rateLimiterKey = DiscordRateLimitKey(endpoint: .guildRoles, parameters: ["guild.id": guildId])

        DiscordRateLimiter.executeRequest(request, for: rateLimiterKey, callback: {data, response, error in
            guard case let .array(roles)? = self.jsonFromResponse(data: data, response: response) else {
                callback([])

                return
            }

            callback(DiscordRole.rolesFromArray(roles as! [[String: Any]]).map({ $0.value }))
        })
    }

    /**
        Edits the specified role.

        - parameter permissionOverwrite: The new DiscordRole
        - parameter on: The guild that we are editing on
        - parameter with: The token to authenticate to Discord with
        - parameter callback: An optional callback containing the modified role, if successful.
    */
    public static func modifyGuildRole(_ role: DiscordRole, on guildId: String, with token: DiscordToken,
            callback: ((DiscordRole?) -> Void)?) {
        let roleJSON = role.json

        var request = createRequest(with: token, for: .guildRole, replacing: [
            "guild.id": guildId,
            "role.id": role.id
        ])

        guard let contentData = encodeJSON(roleJSON)?.data(using: .utf8, allowLossyConversion: false) else {
            return
        }

        request.httpMethod = "PATCH"
        request.httpBody = contentData
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(String(contentData.count), forHTTPHeaderField: "Content-Length")

        let rateLimiterKey = DiscordRateLimitKey(endpoint: .guildRoles, parameters: ["guild.id": guildId])

        DiscordRateLimiter.executeRequest(request, for: rateLimiterKey, callback: {data, response, error in
            guard case let .object(role)? = self.jsonFromResponse(data: data, response: response) else {
                callback?(nil)

                return
            }

            callback?(DiscordRole(roleObject: role))
        })
    }

    /**
        Removes a guild role.

        - parameter roleId: The snowflake id of the role
        - parameter on: The snowflake id of the guild
        - parameter with: The token to authenticate to Discord with
        - parameter callback: An optional callback containing the deleted role, if successful.
    */
    public static func removeGuildRole(_ roleId: String, on guildId: String, with token: DiscordToken,
            callback: ((DiscordRole?) -> Void)?) {
        var request = createRequest(with: token, for: .guildRole, replacing: [
            "guild.id": guildId,
            "role.id": roleId
        ])

        request.httpMethod = "DELETE"

        let rateLimiterKey = DiscordRateLimitKey(endpoint: .guildRoles, parameters: ["guild.id": guildId])

        DiscordRateLimiter.executeRequest(request, for: rateLimiterKey, callback: {data, response, error in
            guard case let .object(role)? = self.jsonFromResponse(data: data, response: response) else {
                callback?(nil)

                return
            }

            callback?(DiscordRole(roleObject: role))
        })
    }
}
