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
    public func createWebhook(forChannel channelId: String, options: [DiscordEndpoint.Options.WebhookOption],
                              callback: @escaping (DiscordWebhook?) -> () = {_ in }) {
        var createJSON: [String: Any] = [:]

        for option in options {
            switch option {
            case let .avatar(avatar):
                createJSON["avatar"] = avatar
            case let .name(name):
                createJSON["name"] = name
            }
        }

        DefaultDiscordLogger.Logger.debug("Creating webhook on: %@", type: "DiscordEndpointChannels", args: channelId)

        guard let contentData = JSON.encodeJSONData(createJSON) else { return }

        var request = DiscordEndpoint.createRequest(with: token, for: .channelWebhooks,
                                                    replacing: ["channel.id": channelId])

        request.httpMethod = "POST"
        request.httpBody = contentData
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(String(contentData.count), forHTTPHeaderField: "Content-Length")

        let rateLimiterKey = DiscordRateLimitKey(endpoint: .channelWebhooks, parameters: ["channel.id": channelId])

        rateLimiter.executeRequest(request, for: rateLimiterKey, callback: {data, response, error in
            guard case let .object(webhook)? = JSON.jsonFromResponse(data: data, response: response) else {
                callback(nil)

                return
            }

            callback(DiscordWebhook(webhookObject: webhook))
        })
    }

    /// Default implementation
    public func deleteWebhook(_ webhookId: String, callback: ((Bool) -> ())? = nil) {
        var request = DiscordEndpoint.createRequest(with: token, for: .webhook, replacing: ["webhook.id": webhookId])

        request.httpMethod = "DELETE"

        let rateLimiterKey = DiscordRateLimitKey(endpoint: .webhook, parameters: ["webhook.id": webhookId])

        rateLimiter.executeRequest(request, for: rateLimiterKey, callback: {data, response, error in
            callback?(response?.statusCode == 204)
        })
    }

    /// Default implementation
    public func getWebhook(_ webhookId: String, callback: @escaping (DiscordWebhook?) -> ()) {
        let request = DiscordEndpoint.createRequest(with: token, for: .webhook, replacing: ["webhook.id": webhookId])
        let rateLimiterKey = DiscordRateLimitKey(endpoint: .webhook, parameters: ["webhook.id": webhookId])

        DefaultDiscordLogger.Logger.debug("Getting webhook: %@", type: "DiscordEndpointWebhooks", args: webhookId)

        rateLimiter.executeRequest(request, for: rateLimiterKey, callback: {data, response, error in
            guard case let .object(webhook)? = JSON.jsonFromResponse(data: data, response: response) else {
                callback(nil)

                return
            }

            callback(DiscordWebhook(webhookObject: webhook))
        })
    }

    /// Default implementation
    public func getWebhooks(forChannel channelId: String, callback: @escaping ([DiscordWebhook]) -> ()) {
        let request = DiscordEndpoint.createRequest(with: token, for: .channelWebhooks,
                                                    replacing: ["channel.id": channelId])
        let rateLimiterKey = DiscordRateLimitKey(endpoint: .channelWebhooks, parameters: ["channel.id": channelId])

        DefaultDiscordLogger.Logger.debug("Getting webhooks for channel: %@", type: "DiscordEndpointWebhooks",
                                          args: channelId)

        rateLimiter.executeRequest(request, for: rateLimiterKey, callback: {data, response, error in
            guard case let .array(webhooks)? = JSON.jsonFromResponse(data: data, response: response) else {
                callback([])

                return
            }

            callback(DiscordWebhook.webhooksFromArray(webhooks as! [[String: Any]]))
        })
    }

    /// Default implementation
    public func getWebhooks(forGuild guildId: String, callback: @escaping ([DiscordWebhook]) -> ()) {
        let request = DiscordEndpoint.createRequest(with: token, for: .guildWebhooks, replacing: ["guild.id": guildId])
        let rateLimiterKey = DiscordRateLimitKey(endpoint: .guildWebhooks, parameters: ["guild.id": guildId])

        DefaultDiscordLogger.Logger.debug("Getting webhooks for guild: %@", type: "DiscordEndpointWebhooks",
                                          args: guildId)

        rateLimiter.executeRequest(request, for: rateLimiterKey, callback: {data, response, error in
            guard case let .array(webhooks)? = JSON.jsonFromResponse(data: data, response: response) else {
                callback([])

                return
            }

            callback(DiscordWebhook.webhooksFromArray(webhooks as! [[String: Any]]))
        })
    }

    /// Default implementation
    public func modifyWebhook(_ webhookId: String, options: [DiscordEndpoint.Options.WebhookOption],
                              callback: @escaping (DiscordWebhook?) -> () = {_ in }) {
        var createJSON: [String: Any] = [:]

        for option in options {
            switch option {
            case let .avatar(avatar):
                createJSON["avatar"] = avatar
            case let .name(name):
                createJSON["name"] = name
            }
        }

        DefaultDiscordLogger.Logger.debug("Modifying webhook: %@", type: "DiscordEndpointChannels", args: webhookId)

        guard let contentData = JSON.encodeJSONData(createJSON) else { return }

        var request = DiscordEndpoint.createRequest(with: token, for: .webhook, replacing: ["webhook.id": webhookId])

        request.httpMethod = "PATCH"
        request.httpBody = contentData
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(String(contentData.count), forHTTPHeaderField: "Content-Length")

        let rateLimiterKey = DiscordRateLimitKey(endpoint: .webhook, parameters: ["webhook.id": webhookId])

        rateLimiter.executeRequest(request, for: rateLimiterKey, callback: {data, response, error in
            guard case let .object(webhook)? = JSON.jsonFromResponse(data: data, response: response) else {
                callback(nil)

                return
            }

            callback(DiscordWebhook(webhookObject: webhook))
        })
    }
}
