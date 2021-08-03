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

fileprivate let logger = Logger(label: "DiscordEndpointChannels")

public extension DiscordEndpointConsumer where Self: DiscordUserActor {
    /// Default implementation
    func addPinnedMessage(_ messageId: MessageID,
                                 on channelId: ChannelID,
                                 callback: ((Bool, HTTPURLResponse?) -> ())? = nil) {
        rateLimiter.executeRequest(endpoint: .pinnedMessage(channel: channelId, message: messageId),
                                   token: token,
                                   requestInfo: .put(content: nil, extraHeaders: nil),
                                   callback: { _, response, _ in callback?(response?.statusCode == 204, response) })
    }

    /// Default implementation
    func bulkDeleteMessages(_ messages: [MessageID],
                                   on channelId: ChannelID,
                                   callback: ((Bool, HTTPURLResponse?) -> ())? = nil) {
        guard let contentData = try? DiscordJSON.encode(["messages": messages.map({ $0.description })]) else { return }

        rateLimiter.executeRequest(endpoint: .bulkMessageDelete(channel: channelId),
                                   token: token,
                                   requestInfo: .post(content: .json(contentData), extraHeaders: nil),
                                   callback: { _, response, _ in callback?(response?.statusCode == 204, response) })
    }

    /// Default implementation
    func createInvite(for channelId: ChannelID,
                             options: DiscordEndpoint.Options.CreateInvite,
                             reason: String? = nil,
                             callback: @escaping (DiscordInvite?, HTTPURLResponse?) -> ()) {
        var extraHeaders = [DiscordHeader: String]()

        if let modifyReason = reason {
            extraHeaders[.auditReason] = modifyReason
        }

        guard let contentData = try? DiscordJSON.encode(options) else { return }

        let requestCallback: DiscordRequestCallback = { data, response, error in
            guard let invite: DiscordInvite = DiscordJSON.decodeResponse(data: data, response: response) else {
                callback(nil, response)

                return
            }

            callback(invite, response)
        }

        rateLimiter.executeRequest(endpoint: .channelInvites(channel: channelId),
                                   token: token,
                                   requestInfo: .post(content: .json(contentData), extraHeaders: extraHeaders),
                                   callback: requestCallback)
    }

    /// Default implementation
    func createReaction(for messageId: MessageID,
                        on channelId: ChannelID,
                        emoji: String,
                        callback: ((DiscordMessage?, HTTPURLResponse?) -> ())? = nil) {
        let requestCallback: DiscordRequestCallback = { data, response, error in
            guard let message: DiscordMessage = DiscordJSON.decodeResponse(data: data, response: response) else {
                callback?(nil, response)
                return
            }

            callback?(message, response)
        }
        
        rateLimiter.executeRequest(endpoint: .reactions(channel: channelId, message: messageId, emoji: emoji.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? emoji),
                                   token: token,
                                   requestInfo: .put(content: nil, extraHeaders: nil),
                                   callback: requestCallback)
    }

    /// Default implementation
    func deleteOwnReaction(for messageId: MessageID,
                        on channelId: ChannelID,
                        emoji: String,
                        callback: ((Bool, HTTPURLResponse?) -> ())?) {
        let requestCallback: DiscordRequestCallback = { data, response, error in
            callback?(response?.statusCode == 204, response)
        }
        
        rateLimiter.executeRequest(endpoint: .reactions(channel: channelId, message: messageId, emoji: emoji.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? emoji),
                                   token: token,
                                   requestInfo: .delete(content: nil, extraHeaders: nil),
                                   callback: requestCallback)
    }

    /// Default implementation
    func deleteUserReaction(for messageId: MessageID,
                        on channelId: ChannelID,
                        emoji: String,
                        by userId: UserID,
                        callback: ((Bool, HTTPURLResponse?) -> ())?) {
        let requestCallback: DiscordRequestCallback = { data, response, error in
            callback?(response?.statusCode == 204, response)
        }
        
        rateLimiter.executeRequest(endpoint: .userReactions(channel: channelId, message: messageId, emoji: emoji.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? emoji, user: userId),
                                   token: token,
                                   requestInfo: .delete(content: nil, extraHeaders: nil),
                                   callback: requestCallback)
    }

    /// Default implementation
    func deleteChannel(_ channelId: ChannelID,
                              reason: String? = nil,
                              callback: ((Bool, HTTPURLResponse?) -> ())? = nil) {
        var extraHeaders = [DiscordHeader: String]()

        if let modifyReason = reason {
            extraHeaders[.auditReason] = modifyReason
        }

        rateLimiter.executeRequest(endpoint: .channel(id: channelId),
                                   token: token,
                                   requestInfo: .delete(content: nil, extraHeaders: extraHeaders),
                                   callback: { _, response, _ in callback?(response?.statusCode == 200, response) })
    }

    /// Default implementation
    func deleteChannelPermission(_ overwriteId: OverwriteID,
                                        on channelId: ChannelID,
                                        reason: String? = nil,
                                        callback: ((Bool, HTTPURLResponse?) -> ())? = nil) {
        var extraHeaders = [DiscordHeader: String]()

        if let modifyReason = reason {
            extraHeaders[.auditReason] = modifyReason
        }

        rateLimiter.executeRequest(endpoint: .channelPermission(channel: channelId, overwrite: overwriteId),
                                   token: token,
                                   requestInfo: .delete(content: nil, extraHeaders: extraHeaders),
                                   callback: { _, response, _ in callback?(response?.statusCode == 204, response) })
    }

    /// Default implementation
    func deleteMessage(_ messageId: MessageID,
                              on channelId: ChannelID,
                              callback: ((Bool, HTTPURLResponse?) -> ())? = nil) {
        rateLimiter.executeRequest(endpoint: .channelMessageDelete(channel: channelId, message: messageId),
                                   token: token,
                                   requestInfo: .delete(content: nil, extraHeaders: nil),
                                   callback: { _, response, _ in callback?(response?.statusCode == 204, response) })
    }

    /// Default implementation
    func deletePinnedMessage(_ messageId: MessageID,
                                    on channelId: ChannelID,
                                    callback: ((Bool, HTTPURLResponse?) -> ())? = nil) {
        rateLimiter.executeRequest(endpoint: .pinnedMessage(channel: channelId, message: messageId),
                                   token: token,
                                   requestInfo: .delete(content: nil, extraHeaders: nil),
                                   callback: { _, response, _ in callback?(response?.statusCode == 204, response) })
    }

    /// Default implementation
    func editChannelPermission(_ permissionOverwrite: DiscordPermissionOverwrite,
                                      on channelId: ChannelID,
                                      reason: String? = nil,
                                      callback: ((Bool, HTTPURLResponse?) -> ())? = nil) {
        var extraHeaders = [DiscordHeader: String]()

        if let modifyReason = reason {
            extraHeaders[.auditReason] = modifyReason
        }

        guard let contentData = try? DiscordJSON.encode(permissionOverwrite) else { return }

        rateLimiter.executeRequest(endpoint: .channelPermission(channel: channelId, overwrite: permissionOverwrite.id),
                                   token: token,
                                   requestInfo: .put(content: .json(contentData), extraHeaders: extraHeaders),
                                   callback: { _, response, _ in callback?(response?.statusCode == 204, response) })
    }

    /// Default implementation
    func getInvites(for channelId: ChannelID,
                           callback: @escaping ([DiscordInvite], HTTPURLResponse?) -> ()) {
        let requestCallback: DiscordRequestCallback = { data, response, error in
            guard let invites: [DiscordInvite] = DiscordJSON.decodeResponse(data: data, response: response) else {
                callback([], response)
                return
            }

            callback(invites, response)
        }

        rateLimiter.executeRequest(endpoint: .channelInvites(channel: channelId),
                                   token: token,
                                   requestInfo: .get(params: nil, extraHeaders: nil),
                                   callback: requestCallback)
    }

    /// Default implementation
    func editMessage(_ messageId: MessageID,
                            on channelId: ChannelID,
                            content: String,
                            callback: ((DiscordMessage?, HTTPURLResponse?) -> ())? = nil) {
        guard let contentData = try? DiscordJSON.encode(["content": content]) else { return }

        let requestCallback: DiscordRequestCallback = { data, response, error in
            guard let message: DiscordMessage = DiscordJSON.decodeResponse(data: data, response: response) else {
                callback?(nil, response)
                return
            }

            callback?(message, response)
        }

        rateLimiter.executeRequest(endpoint: .channelMessage(channel: channelId, message: messageId),
                                   token: token,
                                   requestInfo: .patch(content: .json(contentData), extraHeaders: nil),
                                   callback: requestCallback)
    }

    /// Default implementation
    func getChannel(_ channelId: ChannelID,
                           callback: @escaping (DiscordChannel?, HTTPURLResponse?) -> ()) {
        let requestCallback: DiscordRequestCallback = {data, response, error in
            guard let channel: DiscordChannel = DiscordJSON.decodeResponse(data: data, response: response) else {
                callback(nil, response)
                return
            }

            callback(channel, response)
        }

        rateLimiter.executeRequest(endpoint: .channel(id: channelId),
                                   token: token,
                                   requestInfo: .get(params: nil, extraHeaders: nil),
                                   callback: requestCallback)
    }

    /// Default implementation
    func getMessages(for channelId: ChannelID,
                            selection: DiscordEndpoint.Options.MessageSelection? = nil,
                            limit: Int? = nil,
                            callback: @escaping ([DiscordMessage], HTTPURLResponse?) -> ()) {
        var getParams: [String: String] = [:]

        if let (selectionType, selectionMessage) = selection?.messageParam {
            getParams[selectionType] = String(describing: selectionMessage)
        }
        if let limit = limit {
            getParams["limit"] = String(limit)
        }

        let requestCallback: DiscordRequestCallback = {data, response, error in
            guard let messages: [DiscordMessage] = DiscordJSON.decodeResponse(data: data, response: response) else {
                callback([], response)
                return
            }

            callback(messages, response)
        }

        rateLimiter.executeRequest(endpoint: .messages(channel: channelId),
                                   token: token,
                                   requestInfo: .get(params: getParams, extraHeaders: nil),
                                   callback: requestCallback)
    }

    /// Default implementation
    func getPinnedMessages(for channelId: ChannelID,
                                  callback: @escaping ([DiscordMessage], HTTPURLResponse?) -> ()) {
        let requestCallback: DiscordRequestCallback = {data, response, error in
            guard let messages: [DiscordMessage] = DiscordJSON.decodeResponse(data: data, response: response) else {
                callback([], response)
                return
            }

            callback(messages, response)
        }

        rateLimiter.executeRequest(endpoint: .pins(channel: channelId),
                                   token: token,
                                   requestInfo: .get(params: nil, extraHeaders: nil),
                                   callback: requestCallback)
    }

    /// Default implementation
    func modifyChannel(_ channelId: ChannelID,
                              options: DiscordEndpoint.Options.ModifyChannel,
                              reason: String? = nil,
                              callback: ((DiscordChannel?, HTTPURLResponse?) -> ())? = nil) {
        var extraHeaders = [DiscordHeader: String]()

        if let modifyReason = reason {
            extraHeaders[.auditReason] = modifyReason
        }

        guard let contentData = try? DiscordJSON.encode(options) else { return }

        let requestCallback: DiscordRequestCallback = {data, response, error in
            guard let channel: DiscordChannel = DiscordJSON.decodeResponse(data: data, response: response) else {
                callback?(nil, response)

                return
            }

            callback?(channel, response)
        }

        rateLimiter.executeRequest(endpoint: .channel(id: channelId),
                                   token: token,
                                   requestInfo: .patch(content: .json(contentData), extraHeaders: extraHeaders),
                                   callback: requestCallback)
    }

    /// Default implementation.
    func sendMessage(_ message: DiscordMessage,
                            to channelId: ChannelID,
                            callback: ((DiscordMessage?, HTTPURLResponse?) -> ())? = nil) {
        let requestInfo: DiscordEndpoint.EndpointRequest

        switch message.createDataForSending() {
        case let .left(data):
            requestInfo = .post(content: .json(data), extraHeaders: nil)
        case let .right((boundary, body)):
            requestInfo = .post(content: .other(type: "multipart/form-data; boundary=\(boundary)", body: body),
                                extraHeaders: nil)
        }

        logger.info("Sending message to: \(channelId)")
        logger.debug("(verbose) Message: \(message)")

        let requestCallback: DiscordRequestCallback = { data, response, error in
            guard let message: DiscordMessage = DiscordJSON.decodeResponse(data: data, response: response) else {
                callback?(nil, response)

                return
            }

            callback?(message, response)
        }

        rateLimiter.executeRequest(endpoint: .messages(channel: channelId),
                                   token: token,
                                   requestInfo: requestInfo,
                                   callback: requestCallback)
    }

    /**
     Sends multiple messages in a row

     Guarantees that the messages will be sent (and received by Discord) in the specified order
     - parameter messages: The list of messages to send
     - parameter channelID: The ID of the channel to send the messages to
     - parameter callback: The function that will be called after all messages are sent or one fails to send.
        The HTTPURLResponse will be from the last attempt to send a message (first failure or final success).
        If all messages were sent successfully, the length of the array will be the same as the length of the input.
        Otherwise, the callback's array will be shorter.
    */
    func sendMessages(_ messages: [DiscordMessage],
                             to channelID: ChannelID,
                             callback: (([DiscordMessage], HTTPURLResponse?) -> ())? = nil ) {
        guard let firstMessage = messages.first else {
            callback?([], nil)
            return
        }

        var messagesToSend = messages.dropFirst()
        var sentMessages: [DiscordMessage] = []

        // This function strongly captures `self` (which, being a protocol that doesn't require
        // its implementors to be classes, can't be made weak).  It shouldn't lead to any reference
        // cycles due to the fact that `self` never holds onto a reference to the function.
        // It does, however, keep `self` alive until all messages are sent.  If this is undesirable,
        // maybe we should include an `: AnyClass` on `DiscordEndpointConsumer`
        func handlerFunc(sentMessage: DiscordMessage?, response: HTTPURLResponse?) {
            guard let sentMessage = sentMessage else {
                callback?(sentMessages, response)
                return
            }
            if callback != nil { // Save a bit of memory in the case that we won't need `sentMessages`
                sentMessages.append(sentMessage)
            }
            guard let nextMessage = messagesToSend.first else {
                callback?(sentMessages, response)
                return
            }
            messagesToSend = messagesToSend.dropFirst()
            sendMessage(nextMessage, to: channelID, callback: handlerFunc)
        }
        sendMessage(firstMessage, to: channelID, callback: handlerFunc)
    }

    /// Default implementation
    func triggerTyping(on channelId: ChannelID, callback: ((Bool, HTTPURLResponse?) -> ())? = nil) {
        rateLimiter.executeRequest(endpoint: .typing(channel: channelId),
                                   token: token,
                                   requestInfo: .post(content: nil, extraHeaders: nil),
                                   callback: { _, response, _ in callback?(response?.statusCode == 204, response) })
    }

    /// Default implementation
    func startThread(in channelId: ChannelID,
                     with messageId: MessageID,
                     options: DiscordEndpoint.Options.StartThreadWithMessage,
                     reason: String? = nil,
                     callback: ((DiscordChannel?, HTTPURLResponse?) -> ())?) {
        var extraHeaders = [DiscordHeader: String]()

        if let modifyReason = reason {
            extraHeaders[.auditReason] = modifyReason
        }

        let requestCallback: DiscordRequestCallback = { data, response, error in
            guard let thread: DiscordChannel = DiscordJSON.decodeResponse(data: data, response: response) else {
                callback?(nil, response)
                return
            }
            callback?(thread, response)
        }

        guard let contentData = try? DiscordJSON.encode(options) else { return }

        rateLimiter.executeRequest(endpoint: .channelMessageThreads(channel: channelId, message: messageId),
                                   token: token,
                                   requestInfo: .post(content: .json(contentData), extraHeaders: extraHeaders),
                                   callback: requestCallback)
    }

    /// Default implementation
    func startThread(in channelId: ChannelID,
                     options: DiscordEndpoint.Options.StartThread,
                     reason: String? = nil,
                     callback: ((DiscordChannel?, HTTPURLResponse?) -> ())?) {
        var extraHeaders = [DiscordHeader: String]()

        if let modifyReason = reason {
            extraHeaders[.auditReason] = modifyReason
        }

        let requestCallback: DiscordRequestCallback = { data, response, error in
            guard let thread: DiscordChannel = DiscordJSON.decodeResponse(data: data, response: response) else {
                callback?(nil, response)
                return
            }
            callback?(thread, response)
        }

        guard let contentData = try? DiscordJSON.encode(options) else { return }

        rateLimiter.executeRequest(endpoint: .channelThreads(channel: channelId),
                                   token: token,
                                   requestInfo: .post(content: .json(contentData), extraHeaders: extraHeaders),
                                   callback: requestCallback)
    }
    
    /// Default implementation
    func joinThread(in threadId: ChannelID,
                    callback: ((Bool, HTTPURLResponse?) -> ())?) {
        rateLimiter.executeRequest(endpoint: .threadMember(channel: threadId),
                                   token: token,
                                   requestInfo: .put(content: nil, extraHeaders: nil),
                                   callback: { _, response, _ in callback?(response?.statusCode == 204, response) })
    }

    /// Default implementation
    func addThreadMember(_ userId: UserID,
                         to threadId: ChannelID,
                         callback: ((Bool, HTTPURLResponse?) -> ())?) {
        rateLimiter.executeRequest(endpoint: .userThreadMember(channel: threadId, user: userId),
                                   token: token,
                                   requestInfo: .put(content: nil, extraHeaders: nil),
                                   callback: { _, response, _ in callback?(response?.statusCode == 204, response) })
    }

    /// Default implementation
    func leaveThread(in threadId: ChannelID,
                     callback: ((Bool, HTTPURLResponse?) -> ())?) {
        rateLimiter.executeRequest(endpoint: .threadMember(channel: threadId),
                                   token: token,
                                   requestInfo: .delete(content: nil, extraHeaders: nil),
                                   callback: { _, response, _ in callback?(response?.statusCode == 204, response) })
    }

    /// Default implementation
    func removeThreadMember(_ userId: UserID,
                            from threadId: ChannelID,
                            callback: ((Bool, HTTPURLResponse?) -> ())?) {
        rateLimiter.executeRequest(endpoint: .userThreadMember(channel: threadId, user: userId),
                                   token: token,
                                   requestInfo: .delete(content: nil, extraHeaders: nil),
                                   callback: { _, response, _ in callback?(response?.statusCode == 204, response) })
    }
}
