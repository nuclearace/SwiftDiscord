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
        rateLimiter.executeRequest(endpoint: .pinnedMessage(channel: channelId, message: messageId),
                                   token: token,
                                   method: .put(content: nil),
                                   callback: { _, response, _ in callback?(response?.statusCode == 204) })
    }

    /// Default implementation
    public func bulkDeleteMessages(_ messages: [String], on channelId: String, callback: ((Bool) -> ())? = nil) {
        guard let contentData = JSON.encodeJSONData(["messages": messages]) else { return }
        rateLimiter.executeRequest(endpoint: .bulkMessageDelete(channel: channelId),
                                   token: token,
                                   method: .post(content: (contentData, type: .json)),
                                   callback: { _, response, _ in callback?(response?.statusCode == 204) })
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

        let requestCallback: DiscordRequestCallback = { data, response, error in
            guard case let .object(invite)? = JSON.jsonFromResponse(data: data, response: response) else {
                callback(nil)

                return
            }
            callback(DiscordInvite(inviteObject: invite))
        }

        rateLimiter.executeRequest(endpoint: .channelInvites(channel: channelId),
                                   token: token,
                                   method: .post(content: (contentData, type: .json)),
                                   callback: requestCallback)
    }

    /// Default implementation
    public func deleteChannel(_ channelId: String, callback: ((Bool) -> ())? = nil) {
        rateLimiter.executeRequest(endpoint: .channel(id: channelId),
                                   token: token,
                                   method: .delete,
                                   callback: { _, response, _ in callback?(response?.statusCode == 200) })
    }

    /// Default implementation
    public func deleteChannelPermission(_ overwriteId: String, on channelId: String, callback: ((Bool) -> ())? = nil) {
        rateLimiter.executeRequest(endpoint: .channelPermission(channel: channelId, overwrite: overwriteId),
                                   token: token,
                                   method: .delete,
                                   callback: { _, response, _ in callback?(response?.statusCode == 204) })
    }

    /// Default implementation
    public func deleteMessage(_ messageId: String, on channelId: String, callback: ((Bool) -> ())? = nil) {
        rateLimiter.executeRequest(endpoint: .channelMessageDelete(channel: channelId, message: messageId),
                                   token: token,
                                   method: .delete,
                                   callback: { _, response, _ in callback?(response?.statusCode == 204) })
    }

    /// Default implementation
    public func deletePinnedMessage(_ messageId: String, on channelId: String, callback: ((Bool) -> ())? = nil) {
        rateLimiter.executeRequest(endpoint: .pinnedMessage(channel: channelId, message: messageId),
                                   token: token,
                                   method: .delete,
                                   callback: { _, response, _ in callback?(response?.statusCode == 204) })
    }

    /// Default implementation
    public func editChannelPermission(_ permissionOverwrite: DiscordPermissionOverwrite, on channelId: String,
                                      callback: ((Bool) -> ())? = nil) {
        guard let contentData = JSON.encodeJSONData(permissionOverwrite.json) else { return }

        rateLimiter.executeRequest(endpoint: .channelPermission(channel: channelId, overwrite: permissionOverwrite.id),
                                   token: token,
                                   method: .put(content: (contentData, type: .json)),
                                   callback: { _, response, _ in callback?(response?.statusCode == 204) })
    }

    /// Default implementation
    public func getInvites(for channelId: String, callback: @escaping ([DiscordInvite]) -> ()) {

        let requestCallback: DiscordRequestCallback = { data, response, error in
            guard case let .array(invites)? = JSON.jsonFromResponse(data: data, response: response) else {
                callback([])
                return
            }
            callback(DiscordInvite.invitesFromArray(inviteArray: invites as! [[String: Any]]))
        }

        rateLimiter.executeRequest(endpoint: .channelInvites(channel: channelId),
                                   token: token,
                                   method: .get(params: nil),
                                   callback: requestCallback)
    }

    /// Default implementation
    public func editMessage(_ messageId: String, on channelId: String, content: String,
                            callback: ((DiscordMessage?) -> ())? = nil) {
        guard let contentData = JSON.encodeJSONData(["content": content]) else { return }

        let requestCallback: DiscordRequestCallback = { data, response, error in
            guard case let .object(message)? = JSON.jsonFromResponse(data: data, response: response) else {
                callback?(nil)
                return
            }
            callback?(DiscordMessage(messageObject: message, client: nil))
        }
        rateLimiter.executeRequest(endpoint: .channelMessage(channel: channelId, message: messageId),
                                   token: token,
                                   method: .patch(content: (contentData, type: .json)),
                                   callback: requestCallback)
    }

    /// Default implementation
    public func getChannel(_ channelId: String, callback: @escaping (DiscordChannel?) -> ()) {
        let requestCallback: DiscordRequestCallback = {data, response, error in
            guard case let .object(channel)? = JSON.jsonFromResponse(data: data, response: response) else {
                callback(nil)
                return
            }
            callback(channelFromObject(channel, withClient: nil))
        }
        rateLimiter.executeRequest(endpoint: .channel(id: channelId),
                                   token: token,
                                   method: .get(params: nil),
                                   callback: requestCallback)
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

        let requestCallback: DiscordRequestCallback = {data, response, error in
            guard case let .array(messages)? = JSON.jsonFromResponse(data: data, response: response) else {
                callback([])
                return
            }
            callback(DiscordMessage.messagesFromArray(messages as! [[String: Any]]))
        }
        rateLimiter.executeRequest(endpoint: .messages(channel: channelId),
                                   token: token,
                                   method: .get(params: getParams),
                                   callback: requestCallback)
    }

    /// Default implementation
    public func getPinnedMessages(for channelId: String, callback: @escaping ([DiscordMessage]) -> ()) {
        let requestCallback: DiscordRequestCallback = {data, response, error in
            guard case let .array(messages)? = JSON.jsonFromResponse(data: data, response: response) else {
                callback([])
                return
            }
            callback(DiscordMessage.messagesFromArray(messages as! [[String: Any]]))
        }
        rateLimiter.executeRequest(endpoint: .pins(channel: channelId),
                                   token: token,
                                   method: .get(params: nil),
                                   callback: requestCallback)
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

        let requestCallback: DiscordRequestCallback = {data, response, error in
            guard case let .object(channel)? = JSON.jsonFromResponse(data: data, response: response) else {
                callback?(nil)
                return
            }
            callback?(guildChannelFromObject(channel))
        }
        rateLimiter.executeRequest(endpoint: .channel(id: channelId),
                                   token: token,
                                   method: .patch(content: (contentData, type: .json)),
                                   callback: requestCallback)
    }

    /// Default implementation.
    public func sendMessage(_ message: DiscordMessage, to channelId: String,
                            callback: ((DiscordMessage?) -> ())? = nil) {
        let method: HTTPMethod
        switch message.createDataForSending() {
        case let .left(data):
            method = .post(content: (data, type: .json))
        case let .right((boundary, body)):
            method = .post(content: (body, type: .other("multipart/form-data; boundary=\(boundary)")))
        }
        DefaultDiscordLogger.Logger.log("Sending message to: \(channelId)", type: "DiscordEndpointChannels")
        DefaultDiscordLogger.Logger.verbose("Message: \(message)", type: "DiscordEndpointChannels")

        let requestCallback: DiscordRequestCallback = { data, response, error in
            guard case let .object(message)? = JSON.jsonFromResponse(data: data, response: response) else {
                callback?(nil)
                return
            }
            callback?(DiscordMessage(messageObject: message, client: nil))
        }
        rateLimiter.executeRequest(endpoint: .messages(channel: channelId),
                                   token: token,
                                   method: method,
                                   callback: requestCallback)
    }

    /// Default implementation
    public func triggerTyping(on channelId: String, callback: ((Bool) -> ())? = nil) {
        rateLimiter.executeRequest(endpoint: .typing(channel: channelId),
                                   token: token,
                                   method: .post(content: nil),
                                   callback: { _, response, _ in callback?(response?.statusCode == 204) })
    }
}
