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

public extension DiscordEndpoint {
    // MARK: Channels

    /**
        Gets the specified channel.

        - parameter channelId: The snowflake id of the channel
        - parameter with: The token to authenticate to Discord with
        - parameter callback: The callback function containing an optional `DiscordGuildChannel`
    */
    public static func getChannel(_ channelId: String, with token: DiscordToken,
                                  callback: @escaping (DiscordGuildChannel?) -> ()) {
        var request = createRequest(with: token, for: .channel, replacing: ["channel.id": channelId])

        request.httpMethod = "GET"

        let rateLimiterKey = DiscordRateLimitKey(endpoint: .channel, parameters: ["channel.id": channelId])

        DiscordRateLimiter.executeRequest(request, for: rateLimiterKey, callback: {data, response, error in
            guard case let .object(channel)? = self.jsonFromResponse(data: data, response: response) else {
                callback(nil)

                return
            }

            callback(DiscordGuildChannel(guildChannelObject: channel))
        })
    }

    /**
        Deletes the specified channel.

        - parameter channelId: The snowflake id of the channel
        - parameter with: The token to authenticate to Discord with
        - parameter callback: An optional callback indicating whether the channel was deleted.
    */
    public static func deleteChannel(_ channelId: String, with token: DiscordToken, callback: ((Bool) -> ())?) {
        var request = createRequest(with: token, for: .channel, replacing: [
            "channel.id": channelId,
        ])

        request.httpMethod = "DELETE"

        let rateLimiterKey = DiscordRateLimitKey(endpoint: .channel, parameters: ["channel.id": channelId])

        DiscordRateLimiter.executeRequest(request, for: rateLimiterKey, callback: {data, response, error in
            callback?(response?.statusCode == 200)
        })
    }

    /**
        Modifies the specified channel.

        - parameter channelId: The snowflake id of the channel
        - parameter options: An array of `DiscordEndpointOptions.ModifyChannel` options
        - parameter with: The token to authenticate to Discord with
        - parameter callback: An optional callback containing the edited channel, if successful.
    */
    public static func modifyChannel(_ channelId: String, options: [Options.ModifyChannel],
                                     with token: DiscordToken, callback: ((DiscordGuildChannel?) -> ())?) {
        var modifyJSON: [String: Any] = [:]

        for option in options {
            switch option {
            case let .bitrate(bps):
                modifyJSON["bitrate"] = bps
            case let .name(name):
                modifyJSON["name"] = name
            case let .position(position):
                modifyJSON["position"] = position
            case let .topic(topic):
                modifyJSON["topic"] = topic
            case let .userLimit(limit):
                modifyJSON["user_limit"] = limit
            }
        }

        guard let contentData = JSON.encodeJSONData(modifyJSON) else { return }

        var request = createRequest(with: token, for: .channel, replacing: [
            "channel.id": channelId
        ])

        request.httpMethod = "PATCH"
        request.httpBody = contentData
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(String(contentData.count), forHTTPHeaderField: "Content-Length")

        let rateLimiterKey = DiscordRateLimitKey(endpoint: .channel, parameters: ["channel.id": channelId])

        DiscordRateLimiter.executeRequest(request, for: rateLimiterKey, callback: {data, response, error in
            guard case let .object(channel)? = self.jsonFromResponse(data: data, response: response) else {
                callback?(nil)

                return
            }

            callback?(DiscordGuildChannel(guildChannelObject: channel))
        })
    }

    // Messages

    /**
        Deletes a bunch of messages at once.

        - parameter messages: An array of message snowflake ids that are to be deleted
        - parameter on: The channel that we are deleting on
        - parameter with: The token to authenticate to Discord with
        - parameter callback: An optional callback indicating whether the messages were deleted.
    */
    public static func bulkDeleteMessages(_ messages: [String], on channelId: String, with token: DiscordToken,
                                          callback: ((Bool) -> ())?) {
        var request = createRequest(with: token, for: .bulkMessageDelete, replacing: [
            "channel.id": channelId
        ])

        let editObject = [
            "messages": messages
        ]

        guard let contentData = JSON.encodeJSONData(editObject) else { return }

        request.httpMethod = "POST"
        request.httpBody = contentData
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(String(contentData.count), forHTTPHeaderField: "Content-Length")

        let rateLimiterKey = DiscordRateLimitKey(endpoint: .messages, parameters: ["channel.id": channelId])

        DiscordRateLimiter.executeRequest(request, for: rateLimiterKey, callback: {data, response, error in
            callback?(response?.statusCode == 204)
        })
    }

    /**
        Deletes a single message

        - parameter messageId: The message that is to be deleted's snowflake id
        - parameter on: The channel that we are deleting on
        - parameter with: The token to authenticate to Discord with
        - parameter callback: An optional callback indicating whether the message was deleted.
    */
    public static func deleteMessage(_ messageId: String, on channelId: String, with token: DiscordToken,
                                     callback: ((Bool) -> ())?) {
        var request = createRequest(with: token, for: .channelMessage, replacing: [
            "channel.id": channelId,
            "message.id": messageId
        ])

        request.httpMethod = "DELETE"

        let rateLimiterKey = DiscordRateLimitKey(endpoint: .messages, parameters: ["channel.id": channelId])

        DiscordRateLimiter.executeRequest(request, for: rateLimiterKey, callback: {data, response, error in
            callback?(response?.statusCode == 204)
        })
    }

    /**
        Edits a message

        - parameter messageId: The message that is to be edited's snowflake id
        - parameter on: The channel that we are editing on
        - parameter content: The new content of the message
        - parameter with: The token to authenticate to Discord with
        - parameter callback: An optional callback containing the edited message, if successful
    */
    public static func editMessage(_ messageId: String, on channelId: String, content: String, with token: DiscordToken,
                                   callback: ((DiscordMessage?) -> ())?) {
        var request = createRequest(with: token, for: .channelMessage, replacing: [
            "channel.id": channelId,
            "message.id": messageId
        ])

        let editObject = [
            "content": content
        ]

        guard let contentData = JSON.encodeJSONData(editObject) else { return }

        request.httpMethod = "PATCH"
        request.httpBody = contentData
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(String(contentData.count), forHTTPHeaderField: "Content-Length")

        let rateLimiterKey = DiscordRateLimitKey(endpoint: .messages, parameters: ["channel.id": channelId])

        DiscordRateLimiter.executeRequest(request, for: rateLimiterKey, callback: {data, response, error in
            guard case let .object(message)? = self.jsonFromResponse(data: data, response: response) else {
                callback?(nil)

                return
            }

            callback?(DiscordMessage(messageObject: message, client: nil))
        })
    }

    /**
        Gets a group of messages according to the specified options.

        - parameter for: The channel that we are getting on
        - parameter with: The token to authenticate to Discord with
        - parameter options: An array of `DiscordEndpointOptions.GetMessage` options
        - parameter callback: The callback function, taking an array of `DiscordMessages`
    */
    public static func getMessages(for channel: String, with token: DiscordToken,
                                   options: [Options.GetMessage],
                                   callback: @escaping ([DiscordMessage]) -> ()) {
        var getParams: [String: String] = [:]

        for option in options {
            switch option {
            case let .after(message):
                getParams["after"] = String(message.id)
            case let .around(message):
                getParams["around"] = String(message.id)
            case let .before(message):
                getParams["before"] = String(message.id)
            case let .limit(number):
                getParams["limit"] = String(number)
            }
        }

        var request = createRequest(with: token, for: .messages, replacing: ["channel.id": channel],
                                    getParams: getParams)

        request.httpMethod = "GET"

        let rateLimiterKey = DiscordRateLimitKey(endpoint: .messages, parameters: ["channel.id": channel])

        DiscordRateLimiter.executeRequest(request, for: rateLimiterKey, callback: {data, response, error in
            guard case let .array(messages)? = self.jsonFromResponse(data: data, response: response) else {
                callback([])

                return
            }

            callback(DiscordMessage.messagesFromArray(messages as! [[String: Any]]))
        })
    }

    /**
        Sends a message to the specified channel.

        - parameter message: The content of the message.
        - parameter with: The token to authenticate to Discord with.
        - parameter to: The snowflake id of the channel to send to.
        - parameter callback: An optional callback containing the message, if successful.
    */
    public static func sendMessage(_ message: DiscordMessage, with token: DiscordToken, to channel: String,
                                   callback: ((DiscordMessage?) -> ())?) {
        var request = createRequest(with: token, for: .messages, replacing: ["channel.id": channel])

        DefaultDiscordLogger.Logger.log("Sending message to: %@", type: "DiscordEndpointChannels", args: channel)
        DefaultDiscordLogger.Logger.verbose("Message: %@", type: "DiscordEndpointChannels", args: message)

        request.httpMethod = "POST"

        switch message.createDataForSending() {
        case let .left(data):
            request.httpBody = data
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue(String(data.count), forHTTPHeaderField: "Content-Length")
        case let .right((boundary, body)):
            request.httpBody = body
            request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
            request.setValue(String(body.count), forHTTPHeaderField: "Content-Length")
        }

        let rateLimiterKey = DiscordRateLimitKey(endpoint: .messages, parameters: ["channel.id": channel])

        DiscordRateLimiter.executeRequest(request, for: rateLimiterKey, callback: {data, response, error in
            guard case let .object(message)? = self.jsonFromResponse(data: data, response: response) else {
                callback?(nil)

                return
            }

            callback?(DiscordMessage(messageObject: message, client: nil))
        })
    }

    /**
        Triggers typing on the specified channel.

        - parameter on: The snowflake id of the channel to send to
        - parameter with: The token to authenticate to Discord with
        - parameter callback: An optional callback indicating whether typing was triggered.
    */
    public static func triggerTyping(on channelId: String, with token: DiscordToken, callback: ((Bool) -> ())?) {
        var request = createRequest(with: token, for: .typing, replacing: ["channel.id": channelId])

        request.httpMethod = "POST"

        let rateLimiterKey = DiscordRateLimitKey(endpoint: .typing, parameters: ["channel.id": channelId])

        DiscordRateLimiter.executeRequest(request, for: rateLimiterKey, callback: {data, response, error in
            callback?(response?.statusCode == 204)
        })
    }

    // Permissions
    /**
        Deletes a channel permission

        - parameter overwriteId: The permission overwrite that is to be deleted's snowflake id
        - parameter on: The channel that we are deleting on
        - parameter with: The token to authenticate to Discord with
        - parameter callback: An optional callback indicating whether the permission was deleted.
    */
    public static func deleteChannelPermission(_ overwriteId: String, on channelId: String, with token: DiscordToken,
                                               callback: ((Bool) -> ())?) {
        var request = createRequest(with: token, for: .channelPermission, replacing: [
            "channel.id": channelId,
            "overwrite.id": overwriteId
        ])

        request.httpMethod = "DELETE"

        let rateLimiterKey = DiscordRateLimitKey(endpoint: .permissions, parameters: ["channel.id": channelId])

        DiscordRateLimiter.executeRequest(request, for: rateLimiterKey, callback: {data, response, error in
            callback?(response?.statusCode == 204)
        })
    }

    /**
        Edits the specified permission overwrite.

        - parameter permissionOverwrite: The new DiscordPermissionOverwrite
        - parameter on: The channel that we are editing on
        - parameter with: The token to authenticate to Discord with
        - parameter callback: An optional callback indicating whether the edit was successful.
    */
    public static func editChannelPermission(_ permissionOverwrite: DiscordPermissionOverwrite, on channelId: String,
                                             with token: DiscordToken, callback: ((Bool) -> ())?) {
        let overwriteJSON = permissionOverwrite.json

        guard let contentData = JSON.encodeJSONData(overwriteJSON) else { return }

        var request = createRequest(with: token, for: .channelPermission, replacing: [
            "channel.id": channelId,
            "overwrite.id": permissionOverwrite.id
        ])

        request.httpMethod = "PUT"
        request.httpBody = contentData
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(String(contentData.count), forHTTPHeaderField: "Content-Length")

        let rateLimiterKey = DiscordRateLimitKey(endpoint: .permissions, parameters: ["channel.id": channelId])

        DiscordRateLimiter.executeRequest(request, for: rateLimiterKey, callback: {data, response, error in
            callback?(response?.statusCode == 204)
        })
    }

    // Invites
    /**
        Creates an invite for a channel/guild.

        - parameter for: The channel that we are creating for
        - parameter options: An array of `DiscordEndpointOptions.CreateInvite` options
        - parameter with: The token to authenticate to Discord with
        - parameter callback: The callback function. Takes an optional `DiscordInvite`
    */
    public static func createInvite(for channelId: String, options: [Options.CreateInvite],
                                    with token: DiscordToken, callback: @escaping (DiscordInvite?) -> ()) {
        var inviteJSON: [String: Any] = [:]

        for option in options {
            switch option {
            case let .maxAge(seconds):
                inviteJSON["max_age"] = seconds
            case let .maxUses(uses):
                inviteJSON["max_uses"] = uses
            case let .temporary(temporary):
                inviteJSON["temporary"] = temporary
            case let .unique(unique):
                inviteJSON["unique"] = unique
            }
        }

        guard let contentData = JSON.encodeJSONData(inviteJSON) else { return }

        var request = createRequest(with: token, for: .channelInvites, replacing: [
            "channel.id": channelId
        ])

        request.httpMethod = "POST"
        request.httpBody = contentData
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(String(contentData.count), forHTTPHeaderField: "Content-Length")

        let rateLimiterKey = DiscordRateLimitKey(endpoint: .channelInvites, parameters: ["channel.id": channelId])

        DiscordRateLimiter.executeRequest(request, for: rateLimiterKey, callback: {data, response, error in
            guard case let .object(invite)? = self.jsonFromResponse(data: data, response: response) else {
                callback(nil)

                return
            }

            callback(DiscordInvite(inviteObject: invite))
        })
    }

    /**
        Gets the invites for a channel.

        - parameter for: The channel that we are getting on
        - parameter with: The token to authenticate to Discord with
        - parameter callback: The callback function, taking an array of `DiscordInvite`
    */
    public static func getInvites(for channelId: String, with token: DiscordToken,
                                  callback: @escaping ([DiscordInvite]) -> ()) {
        var request = createRequest(with: token, for: .channelInvites, replacing: [
            "channel.id": channelId
        ])

        request.httpMethod = "GET"

        let rateLimiterKey = DiscordRateLimitKey(endpoint: .channelInvites, parameters: ["channel.id": channelId])

        DiscordRateLimiter.executeRequest(request, for: rateLimiterKey, callback: {data, response, error in
            guard case let .array(invites)? = self.jsonFromResponse(data: data, response: response) else {
                callback([])

                return
            }

            callback(DiscordInvite.invitesFromArray(inviteArray: invites as! [[String: Any]]))
        })
    }

    // Pinned Messages
    /**
        Adds a pinned message.

        - parameter messageId: The message that is to be pinned's snowflake id
        - parameter on: The channel that we are adding on
        - parameter with: The token to authenticate to Discord with
        - parameter callback: An optional callback indicating whether the pinned message was added.
    */
    public static func addPinnedMessage(_ messageId: String, on channelId: String, with token: DiscordToken,
                                        callback: ((Bool) -> ())?) {
        var request = createRequest(with: token, for: .pinnedMessage, replacing: [
            "channel.id": channelId,
            "message.id": messageId
        ])

        request.httpMethod = "PUT"

        let rateLimiterKey = DiscordRateLimitKey(endpoint: .pins, parameters: ["channel.id": channelId])

        DiscordRateLimiter.executeRequest(request, for: rateLimiterKey, callback: {data, response, error in
            callback?(response?.statusCode == 204)
        })
    }

    /**
        Unpins a message.

        - parameter messageId: The message that is to be unpinned's snowflake id
        - parameter on: The channel that we are unpinning on
        - parameter with: The token to authenticate to Discord with
        - parameter callback: An optional callback indicating whether the message was unpinned.
    */
    public static func deletePinnedMessage(_ messageId: String, on channelId: String, with token: DiscordToken,
                                           callback: ((Bool) -> ())?) {
        var request = createRequest(with: token, for: .pinnedMessage, replacing: [
            "channel.id": channelId,
            "message.id": messageId
        ])

        request.httpMethod = "DELETE"

        let rateLimiterKey = DiscordRateLimitKey(endpoint: .pins, parameters: ["channel.id": channelId])

        DiscordRateLimiter.executeRequest(request, for: rateLimiterKey, callback: {data, response, error in
            callback?(response?.statusCode == 204)
        })
    }

    /**
        Gets the pinned messages for a channel.

        - parameter for: The channel that we are getting the pinned messages for
        - parameter with: The token to authenticate to Discord with
        - parameter callback: The callback function, taking an array of `DiscordMessages`
    */
    public static func getPinnedMessages(for channelId: String, with token: DiscordToken,
                                         callback: @escaping ([DiscordMessage]) -> ()) {
        var request = createRequest(with: token, for: .pins, replacing: ["channel.id": channelId])

        request.httpMethod = "GET"

        let rateLimiterKey = DiscordRateLimitKey(endpoint: .pins, parameters: ["channel.id": channelId])

        DiscordRateLimiter.executeRequest(request, for: rateLimiterKey, callback: {data, response, error in
            guard case let .array(messages)? = self.jsonFromResponse(data: data, response: response) else {
                callback([])

                return
            }

            callback(DiscordMessage.messagesFromArray(messages as! [[String: Any]]))
        })
    }
}
