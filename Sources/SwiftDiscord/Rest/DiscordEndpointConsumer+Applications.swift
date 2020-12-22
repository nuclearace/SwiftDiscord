import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public extension DiscordEndpointConsumer where Self: DiscordUserActor {
    /// Default implementation
    func getApplicationCommands(callback: @escaping ([DiscordApplicationCommand], HTTPURLResponse?) -> ()) {
        guard let applicationId = user?.id else { callback([], nil); return }
        let requestCallback: DiscordRequestCallback = {data, response, error in
            guard case let .array(commands)? = JSON.jsonFromResponse(data: data, response: response) else {
                callback([], response)
                return
            }

            callback(DiscordApplicationCommand.commandsFromArray(commands as! [[String: Any]]), response)
        }
        rateLimiter.executeRequest(endpoint: .globalApplicationCommands(applicationId: applicationId),
                                   token: token,
                                   requestInfo: .get(params: nil, extraHeaders: nil),
                                   callback: requestCallback)
    }

    /// Default implementation
    func getApplicationCommand(_ commandId: CommandID,
                               callback: @escaping (DiscordApplicationCommand?, HTTPURLResponse?) -> ()) {
        guard let applicationId = user?.id else { callback(nil, nil); return }

        // TODO
    }

    /// Default implementation
    func getApplicationCommands(on guildId: GuildID,
                                callback: @escaping ([DiscordApplicationCommand], HTTPURLResponse?) -> ()) {
        guard let applicationId = user?.id else { callback([], nil); return }

        // TODO
    }

    /// Default implementation
    func getApplicationCommand(_ commandId: CommandID,
                               on guildId: GuildID,
                               callback: @escaping (DiscordApplicationCommand?, HTTPURLResponse?) -> ()) {
        guard let applicationId = user?.id else { callback(nil, nil); return }

        // TODO
    }
}
