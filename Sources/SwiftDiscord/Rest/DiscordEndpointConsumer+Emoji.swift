import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import Logging

fileprivate let logger = Logger(label: "DiscordEndpointEmoji")

public extension DiscordEndpointConsumer where Self: DiscordUserActor {
    // Default implementation
    func createGuildEmoji(on guildId: GuildID,
                                name: String,
                                image: String,
                                roles: [RoleID],
                                callback: ((Bool, HTTPURLResponse?) -> ())? = nil) {
        var createJSON = [String: Encodable]()

        createJSON["name"] = name
        createJSON["image"] = image
        createJSON["roles"] = roles.map { String($0.rawValue) }

        guard let contentData = JSON.encodeJSONData(GenericEncodableDictionary(createJSON)) else { return }

        rateLimiter.executeRequest(endpoint: .guildEmojis(guild: guildId),
                                   token: token,
                                   requestInfo: .post(content: .json(contentData), extraHeaders: nil),
                                   callback: { _, response, _ in callback?(response?.statusCode == 204, response) })
    }

    // Default implementation
    func getGuildEmojis(on guildId: GuildID,
                                callback: @escaping ([DiscordEmoji], HTTPURLResponse?) -> ()) {
        let requestCallback: DiscordRequestCallback = { data, response, error in
            guard case let .array(rawEmojis)? = JSON.jsonFromResponse(data: data, response: response),
                       let emojis = rawEmojis as? [[String: Any]] else {
                callback([], response)
                return
            }

            callback(emojis.map(DiscordEmoji.init(emojiObject:)), response)
        }

        rateLimiter.executeRequest(endpoint: .guildEmojis(guild: guildId),
                                   token: token,
                                   requestInfo: .get(params: nil, extraHeaders: nil),
                                   callback: requestCallback)
    }
}
