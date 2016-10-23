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
    public static func getChannel(_ channelId: String, with token: String, isBot bot: Bool,
            callback: @escaping (DiscordGuildChannel?) -> Void) {
        var request = createRequest(with: token, for: .channel, replacing: ["channel.id": channelId], isBot: bot)

        request.httpMethod = "GET"

        let rateLimiterKey = DiscordRateLimitKey(endpoint: .channel, parameters: ["channel.id": channelId])

        DiscordRateLimiter.executeRequest(request, for: rateLimiterKey, callback: {data, response, error in
            guard let data = data, response?.statusCode == 200 else {
                callback(nil)

                return
            }

            guard let stringData = String(data: data, encoding: .utf8), let json = decodeJSON(stringData),
                case let .dictionary(channel) = json else {
                    callback(nil)

                    return
            }

            callback(DiscordGuildChannel(guildChannelObject: channel))
        })
    }

    public static func deleteChannel(_ channelId: String, with token: String, isBot bot: Bool) {
        var request = createRequest(with: token, for: .channel, replacing: [
            "channel.id": channelId,
            ], isBot: bot)

        request.httpMethod = "DELETE"

        let rateLimiterKey = DiscordRateLimitKey(endpoint: .channel, parameters: ["channel.id": channelId])

        DiscordRateLimiter.executeRequest(request, for: rateLimiterKey, callback: {data, response, error in })
    }

    public static func modifyChannel(_ channelId: String, options: [DiscordEndpointOptions.ModifyChannel],
            with token: String, isBot bot: Bool) {
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

        guard let contentData = encodeJSON(modifyJSON)?.data(using: .utf8, allowLossyConversion: false) else {
            return
        }

        var request = createRequest(with: token, for: .channel, replacing: [
            "channel.id": channelId
            ], isBot: bot)

        request.httpMethod = "PATCH"
        request.httpBody = contentData
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(String(contentData.count), forHTTPHeaderField: "Content-Length")

        let rateLimiterKey = DiscordRateLimitKey(endpoint: .channel, parameters: ["channel.id": channelId])

        DiscordRateLimiter.executeRequest(request, for: rateLimiterKey, callback: {data, response, error in })
    }

    // Messages
    public static func bulkDeleteMessages(_ messages: [String], on channelId: String, with token: String,
            isBot bot: Bool) {
        var request = createRequest(with: token, for: .bulkMessageDelete, replacing: [
            "channel.id": channelId
            ], isBot: bot)

        let editObject = [
            "messages": messages
        ]

        guard let contentData = encodeJSON(editObject)?.data(using: .utf8, allowLossyConversion: false) else {
            return
        }

        request.httpMethod = "POST"
        request.httpBody = contentData
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(String(contentData.count), forHTTPHeaderField: "Content-Length")

        let rateLimiterKey = DiscordRateLimitKey(endpoint: .messages, parameters: ["channel.id": channelId])

        DiscordRateLimiter.executeRequest(request, for: rateLimiterKey, callback: {data, response, error in })
    }

    public static func deleteMessage(_ messageId: String, on channelId: String, with token: String, isBot bot: Bool) {
        var request = createRequest(with: token, for: .channelMessage, replacing: [
            "channel.id": channelId,
            "message.id": messageId
            ], isBot: bot)

        request.httpMethod = "DELETE"

        let rateLimiterKey = DiscordRateLimitKey(endpoint: .messages, parameters: ["channel.id": channelId])

        DiscordRateLimiter.executeRequest(request, for: rateLimiterKey, callback: {data, response, error in })
    }

    public static func editMessage(_ messageId: String, on channelId: String, content: String, with token: String,
            isBot bot: Bool) {
        var request = createRequest(with: token, for: .channelMessage, replacing: [
            "channel.id": channelId,
            "message.id": messageId
            ], isBot: bot)

        let editObject = [
            "content": content
        ]

        guard let contentData = encodeJSON(editObject)?.data(using: .utf8, allowLossyConversion: false) else {
            return
        }

        request.httpMethod = "PATCH"
        request.httpBody = contentData
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(String(contentData.count), forHTTPHeaderField: "Content-Length")

        let rateLimiterKey = DiscordRateLimitKey(endpoint: .messages, parameters: ["channel.id": channelId])

        DiscordRateLimiter.executeRequest(request, for: rateLimiterKey, callback: {data, response, error in })
    }

    public static func getMessages(for channel: String, with token: String,
            options: [DiscordEndpointOptions.GetMessage], isBot bot: Bool,
            callback: @escaping ([DiscordMessage]) -> Void) {
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

        var request = createRequest(with: token, for: .messages, replacing: ["channel.id": channel], isBot: bot,
            getParams: getParams)

        request.httpMethod = "GET"

        let rateLimiterKey = DiscordRateLimitKey(endpoint: .messages, parameters: ["channel.id": channel])

        DiscordRateLimiter.executeRequest(request, for: rateLimiterKey, callback: {data, response, error in
            guard let data = data, response?.statusCode == 200 else {
                callback([])

                return
            }

            guard let stringData = String(data: data, encoding: .utf8), let json = decodeJSON(stringData),
                case let .array(messages) = json else {
                    callback([])

                    return
            }

            callback(DiscordMessage.messagesFromArray(messages as! [[String: Any]]))
        })
    }

    public static func sendMessage(_ content: String, with token: String, to channel: String, tts: Bool,
            isBot bot: Bool) {
        let messageObject: [String: Any] = [
            "content": content,
            "tts": tts
        ]

        guard let contentData = encodeJSON(messageObject)?.data(using: .utf8, allowLossyConversion: false) else {
            return
        }

        var request = createRequest(with: token, for: .messages, replacing: ["channel.id": channel], isBot: bot)

        request.httpMethod = "POST"
        request.httpBody = contentData
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(String(contentData.count), forHTTPHeaderField: "Content-Length")

        let rateLimiterKey = DiscordRateLimitKey(endpoint: .messages, parameters: ["channel.id": channel])

        DiscordRateLimiter.executeRequest(request, for: rateLimiterKey, callback: {data, response, error in })
    }

    public static func triggerTyping(on channelId: String, with token: String, isBot bot: Bool) {
        var request = createRequest(with: token, for: .typing, replacing: ["channel.id": channelId], isBot: bot)

        request.httpMethod = "POST"

        let rateLimiterKey = DiscordRateLimitKey(endpoint: .typing, parameters: ["channel.id": channelId])

        DiscordRateLimiter.executeRequest(request, for: rateLimiterKey, callback: {data, response, error in })
    }

    public static func uploadFile() {

    }

    // Permissions
    public static func deleteChannelPermission(_ overwriteId: String, on channelId: String, with token: String,
            isBot bot: Bool) {
        var request = createRequest(with: token, for: .channelPermission, replacing: [
            "channel.id": channelId,
            "overwrite.id": overwriteId
            ], isBot: bot)

        request.httpMethod = "DELETE"

        let rateLimiterKey = DiscordRateLimitKey(endpoint: .permissions, parameters: ["channel.id": channelId])

        DiscordRateLimiter.executeRequest(request, for: rateLimiterKey, callback: {data, response, error in })
    }

    public static func editChannelPermission(_ permissionOverwrite: DiscordPermissionOverwrite, on channelId: String,
            with token: String, isBot bot: Bool) {
        let overwriteJSON = permissionOverwrite.json

        guard let contentData = encodeJSON(overwriteJSON)?.data(using: .utf8, allowLossyConversion: false) else {
            return
        }

        var request = createRequest(with: token, for: .channelPermission, replacing: [
            "channel.id": channelId,
            "overwrite.id": permissionOverwrite.id
            ], isBot: bot)

        request.httpMethod = "PUT"
        request.httpBody = contentData
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(String(contentData.count), forHTTPHeaderField: "Content-Length")

        let rateLimiterKey = DiscordRateLimitKey(endpoint: .permissions, parameters: ["channel.id": channelId])

        DiscordRateLimiter.executeRequest(request, for: rateLimiterKey, callback: {data, response, error in })
    }

    // Invites
    public static func createInvite(for channelId: String, options: [DiscordEndpointOptions.CreateInvite],
            with token: String, isBot bot: Bool, callback: @escaping (DiscordInvite?) -> Void) {
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

        guard let contentData = encodeJSON(inviteJSON)?.data(using: .utf8, allowLossyConversion: false) else {
            return
        }

        var request = createRequest(with: token, for: .channelInvites, replacing: [
            "channel.id": channelId
            ], isBot: bot)

        request.httpMethod = "POST"
        request.httpBody = contentData
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(String(contentData.count), forHTTPHeaderField: "Content-Length")

        let rateLimiterKey = DiscordRateLimitKey(endpoint: .channelInvites, parameters: ["channel.id": channelId])

        DiscordRateLimiter.executeRequest(request, for: rateLimiterKey, callback: {data, response, error in
            guard let data = data, response?.statusCode == 200 else {
                callback(nil)

                return
            }

            guard let stringData = String(data: data, encoding: .utf8), let json = decodeJSON(stringData),
                case let .dictionary(invite) = json else {
                    callback(nil)

                    return
            }

            print(DiscordInvite(inviteObject: invite))
        })
    }

    public static func getInvites(for channelId: String, with token: String, isBot bot: Bool,
            callback: @escaping ([DiscordInvite]) -> Void) {
        var request = createRequest(with: token, for: .channelInvites, replacing: [
            "channel.id": channelId
            ], isBot: bot)

        request.httpMethod = "GET"

        let rateLimiterKey = DiscordRateLimitKey(endpoint: .channelInvites, parameters: ["channel.id": channelId])

        DiscordRateLimiter.executeRequest(request, for: rateLimiterKey, callback: {data, response, error in
            guard let data = data, response?.statusCode == 200 else {
                callback([])

                return
            }

            guard let stringData = String(data: data, encoding: .utf8), let json = decodeJSON(stringData),
                case let .array(invites) = json else {
                    callback([])

                    return
            }

            callback(DiscordInvite.invitesFromArray(inviteArray: invites as! [[String: Any]]))
        })
    }

    // Pinned Messages
    public static func addPinnedMessage(_ messageId: String, on channelId: String, with token: String,
            isBot bot: Bool) {
        var request = createRequest(with: token, for: .pinnedMessage, replacing: [
            "channel.id": channelId,
            "message.id": messageId
            ], isBot: bot)

        request.httpMethod = "PUT"

        let rateLimiterKey = DiscordRateLimitKey(endpoint: .pins, parameters: ["channel.id": channelId])

        DiscordRateLimiter.executeRequest(request, for: rateLimiterKey, callback: {data, response, error in })
    }

    public static func deletePinnedMessage(_ messageId: String, on channelId: String, with token: String,
            isBot bot: Bool) {
        var request = createRequest(with: token, for: .pinnedMessage, replacing: [
            "channel.id": channelId,
            "message.id": messageId
            ], isBot: bot)

        request.httpMethod = "DELETE"

        let rateLimiterKey = DiscordRateLimitKey(endpoint: .pins, parameters: ["channel.id": channelId])

        DiscordRateLimiter.executeRequest(request, for: rateLimiterKey, callback: {data, response, error in })
    }

    public static func getPinnedMessages(for channelId: String, with token: String, isBot bot: Bool,
            callback: @escaping ([DiscordMessage]) -> Void) {
        var request = createRequest(with: token, for: .pins, replacing: ["channel.id": channelId], isBot: bot)

        request.httpMethod = "GET"

        let rateLimiterKey = DiscordRateLimitKey(endpoint: .pins, parameters: ["channel.id": channelId])

        DiscordRateLimiter.executeRequest(request, for: rateLimiterKey, callback: {data, response, error in
            guard let data = data, response?.statusCode == 200 else {
                callback([])

                return
            }

            guard let stringData = String(data: data, encoding: .utf8), let json = decodeJSON(stringData),
                case let .array(messages) = json else {
                    callback([])

                    return
            }

            callback(DiscordMessage.messagesFromArray(messages as! [[String: Any]]))
        })
    }
}
