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
    public func addPinnedMessage(_ messageId: MessageID, on channelId: ChannelID, callback: ((Bool) -> ())? = nil) {
        rateLimiter.executeRequest(endpoint: .pinnedMessage(channel: channelId, message: messageId),
                                   token: token,
                                   requestInfo: .put(content: nil, extraHeaders: nil),
                                   callback: { _, response, _ in callback?(response?.statusCode == 204) })
    }

    /// Default implementation
    public func bulkDeleteMessages(_ messages: [MessageID], on channelId: ChannelID, callback: ((Bool) -> ())? = nil) {
        guard let contentData = JSON.encodeJSONData(["messages": messages.map({ $0.description })]) else { return }

        rateLimiter.executeRequest(endpoint: .bulkMessageDelete(channel: channelId),
                                   token: token,
                                   requestInfo: .post(content: .json(contentData), extraHeaders: nil),
                                   callback: { _, response, _ in callback?(response?.statusCode == 204) })
    }

    /// Default implementation
    public func createInvite(for channelId: ChannelID,
                             options: [DiscordEndpoint.Options.CreateInvite],
                             reason: String? = nil,
                             callback: @escaping (DiscordInvite?) -> ()) {
        var inviteJSON: [String: Any] = [:]
        var extraHeaders = [DiscordHeader: String]()

        if let modifyReason = reason {
            extraHeaders[.auditReason] = modifyReason
        }

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
                                   requestInfo: .post(content: .json(contentData), extraHeaders: extraHeaders),
                                   callback: requestCallback)
    }

    /// Default implementation
    public func deleteChannel(_ channelId: ChannelID,
                              reason: String? = nil,
                              callback: ((Bool) -> ())? = nil) {
        var extraHeaders = [DiscordHeader: String]()

        if let modifyReason = reason {
            extraHeaders[.auditReason] = modifyReason
        }

        rateLimiter.executeRequest(endpoint: .channel(id: channelId),
                                   token: token,
                                   requestInfo: .delete(content: nil, extraHeaders: extraHeaders),
                                   callback: { _, response, _ in callback?(response?.statusCode == 200) })
    }

    /// Default implementation
    public func deleteChannelPermission(_ overwriteId: OverwriteID,
                                        on channelId: ChannelID,
                                        reason: String? = nil,
                                        callback: ((Bool) -> ())? = nil) {
        var extraHeaders = [DiscordHeader: String]()

        if let modifyReason = reason {
            extraHeaders[.auditReason] = modifyReason
        }

        rateLimiter.executeRequest(endpoint: .channelPermission(channel: channelId, overwrite: overwriteId),
                                   token: token,
                                   requestInfo: .delete(content: nil, extraHeaders: extraHeaders),
                                   callback: { _, response, _ in callback?(response?.statusCode == 204) })
    }

    /// Default implementation
    public func deleteMessage(_ messageId: MessageID, on channelId: ChannelID, callback: ((Bool) -> ())? = nil) {
        rateLimiter.executeRequest(endpoint: .channelMessageDelete(channel: channelId, message: messageId),
                                   token: token,
                                   requestInfo: .delete(content: nil, extraHeaders: nil),
                                   callback: { _, response, _ in callback?(response?.statusCode == 204) })
    }

    /// Default implementation
    public func deletePinnedMessage(_ messageId: MessageID, on channelId: ChannelID, callback: ((Bool) -> ())? = nil) {
        rateLimiter.executeRequest(endpoint: .pinnedMessage(channel: channelId, message: messageId),
                                   token: token,
                                   requestInfo: .delete(content: nil, extraHeaders: nil),
                                   callback: { _, response, _ in callback?(response?.statusCode == 204) })
    }

    /// Default implementation
    public func editChannelPermission(_ permissionOverwrite: DiscordPermissionOverwrite,
                                      on channelId: ChannelID,
                                      reason: String? = nil,
                                      callback: ((Bool) -> ())? = nil) {
        var extraHeaders = [DiscordHeader: String]()

        if let modifyReason = reason {
            extraHeaders[.auditReason] = modifyReason
        }

        guard let contentData = JSON.encodeJSONData(permissionOverwrite) else { return }

        rateLimiter.executeRequest(endpoint: .channelPermission(channel: channelId, overwrite: permissionOverwrite.id),
                                   token: token,
                                   requestInfo: .put(content: .json(contentData), extraHeaders: extraHeaders),
                                   callback: { _, response, _ in callback?(response?.statusCode == 204) })
    }

    /// Default implementation
    public func getInvites(for channelId: ChannelID, callback: @escaping ([DiscordInvite]) -> ()) {

        let requestCallback: DiscordRequestCallback = { data, response, error in
            guard case let .array(invites)? = JSON.jsonFromResponse(data: data, response: response) else {
                callback([])
                return
            }

            callback(DiscordInvite.invitesFromArray(inviteArray: invites as! [[String: Any]]))
        }

        rateLimiter.executeRequest(endpoint: .channelInvites(channel: channelId),
                                   token: token,
                                   requestInfo: .get(params: nil, extraHeaders: nil),
                                   callback: requestCallback)
    }

    /// Default implementation
    public func editMessage(_ messageId: MessageID, on channelId: ChannelID, content: String,
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
                                   requestInfo: .patch(content: .json(contentData), extraHeaders: nil),
                                   callback: requestCallback)
    }

    /// Default implementation
    public func getChannel(_ channelId: ChannelID, callback: @escaping (DiscordChannel?) -> ()) {
        let requestCallback: DiscordRequestCallback = {data, response, error in
            guard case let .object(channel)? = JSON.jsonFromResponse(data: data, response: response) else {
                callback(nil)
                return
            }

            callback(channelFromObject(channel, withClient: nil))
        }

        rateLimiter.executeRequest(endpoint: .channel(id: channelId),
                                   token: token,
                                   requestInfo: .get(params: nil, extraHeaders: nil),
                                   callback: requestCallback)
    }

    /// Default implementation
    public func getMessages(for channelId: ChannelID, selection: DiscordEndpoint.Options.MessageSelection? = nil,
                            limit: Int? = nil, callback: @escaping ([DiscordMessage]) -> ()) {
        var getParams: [String: String] = [:]

        if let (selectionType, selectionMessage) = selection?.messageParam {
            getParams[selectionType] = String(describing: selectionMessage)
        }
        if let limit = limit {
            getParams["limit"] = String(limit)
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
                                   requestInfo: .get(params: getParams, extraHeaders: nil),
                                   callback: requestCallback)
    }

    /// Default implementation
    public func getPinnedMessages(for channelId: ChannelID, callback: @escaping ([DiscordMessage]) -> ()) {
        let requestCallback: DiscordRequestCallback = {data, response, error in
            guard case let .array(messages)? = JSON.jsonFromResponse(data: data, response: response) else {
                callback([])
                return
            }

            callback(DiscordMessage.messagesFromArray(messages as! [[String: Any]]))
        }

        rateLimiter.executeRequest(endpoint: .pins(channel: channelId),
                                   token: token,
                                   requestInfo: .get(params: nil, extraHeaders: nil),
                                   callback: requestCallback)
    }

    /// Default implementation
    public func modifyChannel(_ channelId: ChannelID,
                              options: [DiscordEndpoint.Options.ModifyChannel],
                              reason: String? = nil,
                              callback: ((DiscordGuildChannel?) -> ())? = nil) {
        var modifyJSON: [String: Any] = [:]
        var extraHeaders = [DiscordHeader: String]()

        if let modifyReason = reason {
            extraHeaders[.auditReason] = modifyReason
        }

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

            callback?(guildChannel(fromObject: channel, guildID: nil))
        }

        rateLimiter.executeRequest(endpoint: .channel(id: channelId),
                                   token: token,
                                   requestInfo: .patch(content: .json(contentData), extraHeaders: extraHeaders),
                                   callback: requestCallback)
    }

    /// Default implementation.
    public func sendMessage(_ message: DiscordMessage, to channelId: ChannelID,
                            callback: ((DiscordMessage?) -> ())? = nil) {
        let requestInfo: DiscordEndpoint.EndpointRequest

        switch message.createDataForSending() {
        case let .left(data):
            requestInfo = .post(content: .json(data), extraHeaders: nil)
        case let .right((boundary, body)):
            requestInfo = .post(content: .other(type: "multipart/form-data; boundary=\(boundary)", body: body),
                                extraHeaders: nil)
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
                                   requestInfo: requestInfo,
                                   callback: requestCallback)
    }

    /// Default implementation
    public func triggerTyping(on channelId: ChannelID, callback: ((Bool) -> ())? = nil) {
        rateLimiter.executeRequest(endpoint: .typing(channel: channelId),
                                   token: token,
                                   requestInfo: .post(content: nil, extraHeaders: nil),
                                   callback: { _, response, _ in callback?(response?.statusCode == 204) })
    }
}
