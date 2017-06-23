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
    public func addPinnedMessage(_ messageId: String, on channelId: String, callback: ((Bool) -> ())? = nil) {
        var request = DiscordEndpoint.createRequest(with: token, for: .pinnedMessage, replacing: [
            "channel.id": channelId,
            "message.id": messageId
        ])

        request.httpMethod = "PUT"

        let rateLimiterKey = DiscordRateLimitKey(endpoint: .pins, parameters: ["channel.id": channelId])

        rateLimiter.executeRequest(request, for: rateLimiterKey, callback: {data, response, error in
            callback?(response?.statusCode == 204)
        })
    }

    /// Default implementation
    public func bulkDeleteMessages(_ messages: [String], on channelId: String, callback: ((Bool) -> ())? = nil) {
        var request = DiscordEndpoint.createRequest(with: token, for: .bulkMessageDelete, replacing: [
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

        rateLimiter.executeRequest(request, for: rateLimiterKey, callback: {data, response, error in
            callback?(response?.statusCode == 204)
        })
    }

    /// Default implementation
    public func createInvite(for channelId: String, options: [DiscordEndpoint.Options.CreateInvite],
                             callback: @escaping (DiscordInvite?) -> ()) {
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

        var request = DiscordEndpoint.createRequest(with: token, for: .channelInvites, replacing: [
            "channel.id": channelId
        ])

        request.httpMethod = "POST"
        request.httpBody = contentData
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(String(contentData.count), forHTTPHeaderField: "Content-Length")

        let rateLimiterKey = DiscordRateLimitKey(endpoint: .channelInvites, parameters: ["channel.id": channelId])

        rateLimiter.executeRequest(request, for: rateLimiterKey, callback: {data, response, error in
            guard case let .object(invite)? = JSON.jsonFromResponse(data: data, response: response) else {
                callback(nil)

                return
            }

            callback(DiscordInvite(inviteObject: invite))
        })
    }

    /// Default implementation
    public func deleteChannel(_ channelId: String, callback: ((Bool) -> ())? = nil) {
        var request = DiscordEndpoint.createRequest(with: token, for: .channel, replacing: [
            "channel.id": channelId,
        ])

        request.httpMethod = "DELETE"

        let rateLimiterKey = DiscordRateLimitKey(endpoint: .channel, parameters: ["channel.id": channelId])

        rateLimiter.executeRequest(request, for: rateLimiterKey, callback: {data, response, error in
            callback?(response?.statusCode == 200)
        })
    }

    /// Default implementation
    public func deleteChannelPermission(_ overwriteId: String, on channelId: String, callback: ((Bool) -> ())? = nil) {
        var request = DiscordEndpoint.createRequest(with: token, for: .channelPermission, replacing: [
            "channel.id": channelId,
            "overwrite.id": overwriteId
        ])

        request.httpMethod = "DELETE"

        let rateLimiterKey = DiscordRateLimitKey(endpoint: .permissions, parameters: ["channel.id": channelId])

        rateLimiter.executeRequest(request, for: rateLimiterKey, callback: {data, response, error in
            callback?(response?.statusCode == 204)
        })
    }

    /// Default implementation
    public func deleteMessage(_ messageId: String, on channelId: String, callback: ((Bool) -> ())? = nil) {
        var request = DiscordEndpoint.createRequest(with: token, for: .channelMessage, replacing: [
            "channel.id": channelId,
            "message.id": messageId
        ])

        request.httpMethod = "DELETE"

        let rateLimiterKey = DiscordRateLimitKey(endpoint: .messages, parameters: ["channel.id": channelId])

        rateLimiter.executeRequest(request, for: rateLimiterKey, callback: {data, response, error in
            callback?(response?.statusCode == 204)
        })
    }

    /// Default implementation
    public func deletePinnedMessage(_ messageId: String, on channelId: String, callback: ((Bool) -> ())? = nil) {
        var request = DiscordEndpoint.createRequest(with: token, for: .pinnedMessage, replacing: [
            "channel.id": channelId,
            "message.id": messageId
        ])

        request.httpMethod = "DELETE"

        let rateLimiterKey = DiscordRateLimitKey(endpoint: .pins, parameters: ["channel.id": channelId])

        rateLimiter.executeRequest(request, for: rateLimiterKey, callback: {data, response, error in
            callback?(response?.statusCode == 204)
        })
    }

    /// Default implementation
    public func editChannelPermission(_ permissionOverwrite: DiscordPermissionOverwrite, on channelId: String,
                                      callback: ((Bool) -> ())? = nil) {
        guard let contentData = JSON.encodeJSONData(permissionOverwrite.json) else { return }

        var request = DiscordEndpoint.createRequest(with: token, for: .channelPermission, replacing: [
            "channel.id": channelId,
            "overwrite.id": permissionOverwrite.id
        ])

        request.httpMethod = "PUT"
        request.httpBody = contentData
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(String(contentData.count), forHTTPHeaderField: "Content-Length")

        let rateLimiterKey = DiscordRateLimitKey(endpoint: .permissions, parameters: ["channel.id": channelId])

        rateLimiter.executeRequest(request, for: rateLimiterKey, callback: {data, response, error in
            callback?(response?.statusCode == 204)
        })
    }

    /// Default implementation
    public func getInvites(for channelId: String, callback: @escaping ([DiscordInvite]) -> ()) {
        let request = DiscordEndpoint.createRequest(with: token, for: .channelInvites, replacing: [
            "channel.id": channelId
        ])
        let rateLimiterKey = DiscordRateLimitKey(endpoint: .channelInvites, parameters: ["channel.id": channelId])

        rateLimiter.executeRequest(request, for: rateLimiterKey, callback: {data, response, error in
            guard case let .array(invites)? = JSON.jsonFromResponse(data: data, response: response) else {
                callback([])

                return
            }

            callback(DiscordInvite.invitesFromArray(inviteArray: invites as! [[String: Any]]))
        })
    }

    /// Default implementation
    public func editMessage(_ messageId: String, on channelId: String, content: String,
                            callback: ((DiscordMessage?) -> ())? = nil) {
        var request = DiscordEndpoint.createRequest(with: token, for: .channelMessage, replacing: [
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

        rateLimiter.executeRequest(request, for: rateLimiterKey, callback: {data, response, error in
            guard case let .object(message)? = JSON.jsonFromResponse(data: data, response: response) else {
                callback?(nil)

                return
            }

            callback?(DiscordMessage(messageObject: message, client: nil))
        })
    }

    /// Default implementation
    public func getChannel(_ channelId: String, callback: @escaping (DiscordChannel?) -> ()) {
        let request = DiscordEndpoint.createRequest(with: token, for: .channel, replacing: ["channel.id": channelId])
        let rateLimiterKey = DiscordRateLimitKey(endpoint: .channel, parameters: ["channel.id": channelId])

        rateLimiter.executeRequest(request, for: rateLimiterKey, callback: {data, response, error in
            guard case let .object(channel)? = JSON.jsonFromResponse(data: data, response: response) else {
                callback(nil)

                return
            }

            callback(channelFromObject(channel, withClient: nil))
        })
    }

    /// Default implementation
    public func getMessages(for channelId: String, options: [DiscordEndpoint.Options.GetMessage] = [],
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

        let request = DiscordEndpoint.createRequest(with: token, for: .messages, replacing: ["channel.id": channelId],
                                                    getParams: getParams)
        let rateLimiterKey = DiscordRateLimitKey(endpoint: .messages, parameters: ["channel.id": channelId])

        rateLimiter.executeRequest(request, for: rateLimiterKey, callback: {data, response, error in
            guard case let .array(messages)? = JSON.jsonFromResponse(data: data, response: response) else {
                callback([])

                return
            }

            callback(DiscordMessage.messagesFromArray(messages as! [[String: Any]]))
        })
    }

    /// Default implementation
    public func getPinnedMessages(for channelId: String, callback: @escaping ([DiscordMessage]) -> ()) {
        let request = DiscordEndpoint.createRequest(with: token, for: .pins, replacing: ["channel.id": channelId])
        let rateLimiterKey = DiscordRateLimitKey(endpoint: .pins, parameters: ["channel.id": channelId])

        rateLimiter.executeRequest(request, for: rateLimiterKey, callback: {data, response, error in
            guard case let .array(messages)? = JSON.jsonFromResponse(data: data, response: response) else {
                callback([])

                return
            }

            callback(DiscordMessage.messagesFromArray(messages as! [[String: Any]]))
        })
    }

    /// Default implementation
    public func modifyChannel(_ channelId: String, options: [DiscordEndpoint.Options.ModifyChannel],
                              callback: ((DiscordGuildChannel?) -> ())? = nil) {
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

        var request = DiscordEndpoint.createRequest(with: token, for: .channel, replacing: [
            "channel.id": channelId
        ])

        request.httpMethod = "PATCH"
        request.httpBody = contentData
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(String(contentData.count), forHTTPHeaderField: "Content-Length")

        let rateLimiterKey = DiscordRateLimitKey(endpoint: .channel, parameters: ["channel.id": channelId])

        rateLimiter.executeRequest(request, for: rateLimiterKey, callback: {data, response, error in
            guard case let .object(channel)? = JSON.jsonFromResponse(data: data, response: response) else {
                callback?(nil)

                return
            }

            callback?(guildChannelFromObject(channel))
        })
    }

    /// Default implementation.
    public func sendMessage(_ message: DiscordMessage, to channelId: String,
                            callback: ((DiscordMessage?) -> ())? = nil) {
        var request = DiscordEndpoint.createRequest(with: token, for: .messages, replacing: ["channel.id": channelId])

        DefaultDiscordLogger.Logger.log("Sending message to: \(channelId)", type: "DiscordEndpointChannels")
        DefaultDiscordLogger.Logger.verbose("Message: \(message)", type: "DiscordEndpointChannels")

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

        let rateLimiterKey = DiscordRateLimitKey(endpoint: .messages, parameters: ["channel.id": channelId])

        rateLimiter.executeRequest(request, for: rateLimiterKey, callback: {data, response, error in
            guard case let .object(message)? = JSON.jsonFromResponse(data: data, response: response) else {
                callback?(nil)

                return
            }

            callback?(DiscordMessage(messageObject: message, client: nil))
        })
    }

    /// Default implementation
    public func triggerTyping(on channelId: String, callback: ((Bool) -> ())? = nil) {
        var request = DiscordEndpoint.createRequest(with: token, for: .typing, replacing: ["channel.id": channelId])

        request.httpMethod = "POST"

        let rateLimiterKey = DiscordRateLimitKey(endpoint: .typing, parameters: ["channel.id": channelId])

        rateLimiter.executeRequest(request, for: rateLimiterKey, callback: {data, response, error in
            callback?(response?.statusCode == 204)
        })
    }
}
