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
    // MARK: Webhooks

    /**
        Creates a webhook for a given channel.

        - parameter forChannel: The channel to create the webhook for
        - parameter with: The token to authenticate to Discord with
        - parameter options: The options for this webhook
        - parameter callback: A callback that returns the webhook created, if successful.
    */
    public static func createWebhook(forChannel channelId: String, with token: DiscordToken,
            options: [DiscordEndpointOptions.WebhookOption], callback: @escaping (DiscordWebhook?) -> Void) {
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

        guard let contentData = encodeJSON(createJSON)?.data(using: .utf8, allowLossyConversion: false) else {
            return
        }

        var request = createRequest(with: token, for: .channelWebhooks, replacing: ["channel.id": channelId])

        request.httpMethod = "POST"
        request.httpBody = contentData
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(String(contentData.count), forHTTPHeaderField: "Content-Length")

        let rateLimiterKey = DiscordRateLimitKey(endpoint: .channelWebhooks, parameters: ["channel.id": channelId])

        DiscordRateLimiter.executeRequest(request, for: rateLimiterKey, callback: {data, response, error in
            guard case let .object(webhook)? = self.jsonFromResponse(data: data, response: response) else {
                callback(nil)

                return
            }

            callback(DiscordWebhook(webhookObject: webhook))
        })
    }

    /**
        Deletes the specified webhook.

        - parameter channelId: The snowflake id of the channel
        - parameter with: The token to authenticate to Discord with
        - paramter callback: An optional callback indicating whether the delete was successful
    */
    public static func deleteWebhook(_ webhookId: String, with token: DiscordToken, callback: ((Bool) -> Void)?) {
        var request = createRequest(with: token, for: .webhook, replacing: ["webhook.id": webhookId,])

        request.httpMethod = "DELETE"

        let rateLimiterKey = DiscordRateLimitKey(endpoint: .webhook, parameters: ["webhook.id": webhookId])

        DiscordRateLimiter.executeRequest(request, for: rateLimiterKey, callback: {data, response, error in
            callback?(response?.statusCode == 204)
        })
    }

    /**
        Gets the specified webhook.

        - parameter webhookId: The snowflake id of the webhook
        - parameter with: The token to authenticate to Discord with
        - parameter callback: The callback function taking an optional `DiscordWebhook`
    */
    public static func getWebhook(_ webhookId: String, with token: DiscordToken,
            callback: @escaping (DiscordWebhook?) -> Void) {
        var request = createRequest(with: token, for: .webhook, replacing: ["webhook.id": webhookId])

        request.httpMethod = "GET"

        let rateLimiterKey = DiscordRateLimitKey(endpoint: .webhook, parameters: ["webhook.id": webhookId])

        DefaultDiscordLogger.Logger.debug("Getting webhook: %@", type: "DiscordEndpointWebhooks", args: webhookId)

        DiscordRateLimiter.executeRequest(request, for: rateLimiterKey, callback: {data, response, error in
            guard case let .object(webhook)? = self.jsonFromResponse(data: data, response: response) else {
                callback(nil)

                return
            }

            callback(DiscordWebhook(webhookObject: webhook))
        })
    }

    /**
        Gets the webhooks for a specified channel.

        - parameter forChannel: The snowflake id of the channel.
        - parameter with: The token to authenticate to Discord with
        - parameter callback: The callback function taking an array of `DiscordWebhook`s
    */
    public static func getWebhooks(forChannel channelId: String, with token: DiscordToken,
            callback: @escaping ([DiscordWebhook]) -> Void) {
        var request = createRequest(with: token, for: .channelWebhooks, replacing: ["channel.id": channelId])

        request.httpMethod = "GET"

        let rateLimiterKey = DiscordRateLimitKey(endpoint: .channelWebhooks, parameters: ["channel.id": channelId])

        DefaultDiscordLogger.Logger.debug("Getting webhooks for channel: %@", type: "DiscordEndpointWebhooks",
            args: channelId)

        DiscordRateLimiter.executeRequest(request, for: rateLimiterKey, callback: {data, response, error in
            guard let data = data, response?.statusCode == 200 else {
                callback([])

                return
            }

            guard let stringData = String(data: data, encoding: .utf8), let json = decodeJSON(stringData),
                case let .array(webhooks) = json else {
                    callback([])

                    return
            }

            callback(DiscordWebhook.webhooksFromArray(webhooks as! [[String: Any]]))
        })
    }

    /**
        Gets the webhooks for a specified guild.

        - parameter forGuild: The snowflake id of the guild.
        - parameter with: The token to authenticate to Discord with
        - parameter callback: The callback function taking an array of `DiscordWebhook`s
    */
    public static func getWebhooks(forGuild guildId: String, with token: DiscordToken,
            callback: @escaping ([DiscordWebhook]) -> Void) {
        var request = createRequest(with: token, for: .guildWebhooks, replacing: ["guild.id": guildId])

        request.httpMethod = "GET"

        let rateLimiterKey = DiscordRateLimitKey(endpoint: .guildWebhooks, parameters: ["guild.id": guildId])

        DefaultDiscordLogger.Logger.debug("Getting webhooks for guild: %@", type: "DiscordEndpointWebhooks",
            args: guildId)

        DiscordRateLimiter.executeRequest(request, for: rateLimiterKey, callback: {data, response, error in
            guard case let .array(webhooks)? = self.jsonFromResponse(data: data, response: response) else {
                callback([])

                return
            }

            callback(DiscordWebhook.webhooksFromArray(webhooks as! [[String: Any]]))
        })
    }


    /**
        Modifies a webhook.

        - parameter forChannel: The channel to create the webhook for
        - parameter with: The token to authenticate to Discord with
        - parameter options: The options for this webhook
        - parameter callback: A callback that returns the updated webhook, if successful.
    */
    public static func modifyWebhook(_ webhookId: String, with token: DiscordToken,
            options: [DiscordEndpointOptions.WebhookOption], callback: @escaping (DiscordWebhook?) -> Void) {
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

        guard let contentData = encodeJSON(createJSON)?.data(using: .utf8, allowLossyConversion: false) else {
            return
        }

        var request = createRequest(with: token, for: .webhook, replacing: ["webhook.id": webhookId])

        request.httpMethod = "PATCH"
        request.httpBody = contentData
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(String(contentData.count), forHTTPHeaderField: "Content-Length")

        let rateLimiterKey = DiscordRateLimitKey(endpoint: .webhook, parameters: ["webhook.id": webhookId])

        DiscordRateLimiter.executeRequest(request, for: rateLimiterKey, callback: {data, response, error in
            guard case let .object(webhook)? = self.jsonFromResponse(data: data, response: response) else {
                callback(nil)

                return
            }

            callback(DiscordWebhook(webhookObject: webhook))
        })
    }
}
