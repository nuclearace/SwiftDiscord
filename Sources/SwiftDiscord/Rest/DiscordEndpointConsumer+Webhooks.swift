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

fileprivate let logger = Logger(label: "DiscordEndpointWebhooks")

public extension DiscordEndpointConsumer where Self: DiscordUserActor {
    /// Default implementation
    func createWebhook(forChannel channelId: ChannelID,
                              options: [DiscordEndpoint.Options.WebhookOption],
                              reason: String? = nil,
                              callback: @escaping (DiscordWebhook?, HTTPURLResponse?) -> () = {_, _ in }) {
        var createJSON: [String: Any] = [:]
        var extraHeaders = [DiscordHeader: String]()

        if let modifyReason = reason {
            extraHeaders[.auditReason] = modifyReason
        }

        for option in options {
            switch option {
            case let .avatar(avatar):
                createJSON["avatar"] = avatar
            case let .name(name):
                createJSON["name"] = name
            }
        }

        logger.debug("Creating webhook on: \(channelId)")

        guard let contentData = JSON.encodeJSONData(GenericEncodableDictionary(createJSON)) else { return }

        let requestCallback: DiscordRequestCallback = { data, response, error in
            guard case let .object(webhook)? = JSON.jsonFromResponse(data: data, response: response) else {
                callback(nil, response)

                return
            }

            callback(DiscordWebhook(webhookObject: webhook), response)
        }

        rateLimiter.executeRequest(endpoint: .channelWebhooks(channel: channelId),
                                   token: token,
                                   requestInfo: .post(content: .json(contentData), extraHeaders: extraHeaders),
                                   callback: requestCallback)
    }

    /// Default implementation
    func deleteWebhook(_ webhookId: WebhookID,
                              reason: String? = nil,
                              callback: ((Bool, HTTPURLResponse?) -> ())? = nil) {
        var extraHeaders = [DiscordHeader: String]()

        if let modifyReason = reason {
            extraHeaders[.auditReason] = modifyReason
        }

        rateLimiter.executeRequest(endpoint: .webhook(id: webhookId),
                                   token: token,
                                   requestInfo: .delete(content: nil, extraHeaders: extraHeaders),
                                   callback: { _, response, _ in callback?(response?.statusCode == 204, response) })
    }

    /// Default implementation
    func getWebhook(_ webhookId: WebhookID,
                           callback: @escaping (DiscordWebhook?, HTTPURLResponse?) -> ()) {
        let requestCallback: DiscordRequestCallback = { data, response, error in
            guard case let .object(webhook)? = JSON.jsonFromResponse(data: data, response: response) else {
                callback(nil, response)

                return
            }

            callback(DiscordWebhook(webhookObject: webhook), response)
        }

        rateLimiter.executeRequest(endpoint: .webhook(id: webhookId),
                                   token: token,
                                   requestInfo: .get(params: nil, extraHeaders: nil),
                                   callback: requestCallback)
    }

    /// Default implementation
    func getWebhooks(forChannel channelId: ChannelID,
                            callback: @escaping ([DiscordWebhook], HTTPURLResponse?) -> ()) {
        let requestCallback: DiscordRequestCallback = { data, response, error in
            guard case let .array(webhooks)? = JSON.jsonFromResponse(data: data, response: response) else {
                callback([], response)

                return
            }

            callback(DiscordWebhook.webhooksFromArray(webhooks as! [[String: Any]]), response)
        }

        rateLimiter.executeRequest(endpoint: .channelWebhooks(channel: channelId),
                                   token: token,
                                   requestInfo: .get(params: nil, extraHeaders: nil),
                                   callback: requestCallback)
    }

    /// Default implementation
    func getWebhooks(forGuild guildId: GuildID,
                            callback: @escaping ([DiscordWebhook], HTTPURLResponse?) -> ()) {
        logger.debug("Getting webhooks for guild: \(guildId)")

        let requestCallback: DiscordRequestCallback = { data, response, error in
            guard case let .array(webhooks)? = JSON.jsonFromResponse(data: data, response: response) else {
                callback([], response)

                return
            }

            callback(DiscordWebhook.webhooksFromArray(webhooks as! [[String: Any]]), response)
        }

        rateLimiter.executeRequest(endpoint: .guildWebhooks(guild: guildId),
                                   token: token,
                                   requestInfo: .get(params: nil, extraHeaders: nil),
                                   callback: requestCallback)
    }

    /// Default implementation
    func modifyWebhook(_ webhookId: WebhookID,
                              options: [DiscordEndpoint.Options.WebhookOption],
                              reason: String? = nil,
                              callback: @escaping (DiscordWebhook?, HTTPURLResponse?) -> () = {_, _ in }) {
        var createJSON: [String: Any] = [:]
        var extraHeaders = [DiscordHeader: String]()

        if let modifyReason = reason {
            extraHeaders[.auditReason] = modifyReason
        }

        for option in options {
            switch option {
            case let .avatar(avatar):
                createJSON["avatar"] = avatar
            case let .name(name):
                createJSON["name"] = name
            }
        }

        guard let contentData = JSON.encodeJSONData(GenericEncodableDictionary(createJSON)) else { return }

        logger.debug("Modifying webhook: \(webhookId)")

        let requestCallback: DiscordRequestCallback = { data, response, error in
            guard case let .object(webhook)? = JSON.jsonFromResponse(data: data, response: response) else {
                callback(nil, response)

                return
            }

            callback(DiscordWebhook(webhookObject: webhook), response)
        }

        rateLimiter.executeRequest(endpoint: .webhook(id: webhookId),
                                   token: token,
                                   requestInfo: .patch(content: .json(contentData), extraHeaders: extraHeaders),
                                   callback: requestCallback)
    }
}
