import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

private struct CommandParams: Encodable {
    let name: String
    let description: String
    let options: [DiscordApplicationCommandOption]?
}

public extension DiscordEndpointConsumer where Self: DiscordUserActor {
    /// Default implementation
    func getApplicationCommands(callback: @escaping ([DiscordApplicationCommand], HTTPURLResponse?) -> ()) {
        guard let applicationId = user?.id else { callback([], nil); return }
        let requestCallback: DiscordRequestCallback = { data, response, error in
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
    func createApplicationCommand(name: String,
                                  description: String,
                                  options: [DiscordApplicationCommandOption]? = nil,
                                  callback: ((DiscordApplicationCommand?, HTTPURLResponse?) -> ())? = nil) {
        guard let applicationId = user?.id else { callback?(nil, nil); return }
        let requestCallback: DiscordRequestCallback = { data, response, error in
            guard case let .object(command)? = JSON.jsonFromResponse(data: data, response: response) else {
                callback?(nil, response)
                return
            }

            callback?(DiscordApplicationCommand(commandObject: command), response)
        }
        let params = CommandParams(name: name, description: description, options: options)
        rateLimiter.executeRequest(endpoint: .globalApplicationCommands(applicationId: applicationId),
                                   token: token,
                                   requestInfo: .post(content: .json(JSON.encodeJSONData(params) ?? Data()), extraHeaders: nil),
                                   callback: requestCallback)
    }

    /// Default implementation
    func editApplicationCommand(_ commandId: CommandID,
                                name: String,
                                description: String,
                                options: [DiscordApplicationCommandOption]? = nil,
                                callback: ((DiscordApplicationCommand?, HTTPURLResponse?) -> ())? = nil) {
        guard let applicationId = user?.id else { callback?(nil, nil); return }
        let requestCallback: DiscordRequestCallback = { data, response, error in
            guard case let .object(command)? = JSON.jsonFromResponse(data: data, response: response) else {
                callback?(nil, response)
                return
            }

            callback?(DiscordApplicationCommand(commandObject: command), response)
        }
        let params = CommandParams(name: name, description: description, options: options)
        rateLimiter.executeRequest(endpoint: .globalApplicationCommand(applicationId: applicationId, commandId: commandId),
                                   token: token,
                                   requestInfo: .patch(content: .json(JSON.encodeJSONData(params) ?? Data()), extraHeaders: nil),
                                   callback: requestCallback)
    }

    /// Default implementation
    func deleteApplicationCommand(_ commandId: CommandID,
                                  callback: ((HTTPURLResponse?) -> ())? = nil) {
        guard let applicationId = user?.id else { callback?(nil); return }
        let requestCallback: DiscordRequestCallback = { data, response, error in
            callback?(response)
        }
        rateLimiter.executeRequest(endpoint: .globalApplicationCommand(applicationId: applicationId, commandId: commandId),
                                   token: token,
                                   requestInfo: .delete(content: nil, extraHeaders: nil),
                                   callback: requestCallback)
    }

    /// Default implementation
    func getApplicationCommands(on guildId: GuildID,
                                callback: @escaping ([DiscordApplicationCommand], HTTPURLResponse?) -> ()) {
        guard let applicationId = user?.id else { callback([], nil); return }
        let requestCallback: DiscordRequestCallback = { data, response, error in
            guard case let .array(commands)? = JSON.jsonFromResponse(data: data, response: response) else {
                callback([], response)
                return
            }

            callback(DiscordApplicationCommand.commandsFromArray(commands as! [[String: Any]]), response)
        }
        rateLimiter.executeRequest(endpoint: .guildApplicationCommands(applicationId: applicationId, guildId: guildId),
                                   token: token,
                                   requestInfo: .get(params: nil, extraHeaders: nil),
                                   callback: requestCallback)
    }

    /// Default implementation
    func createApplicationCommand(on guildId: GuildID,
                                  name: String,
                                  description: String,
                                  options: [DiscordApplicationCommandOption]? = nil,
                                  callback: ((DiscordApplicationCommand?, HTTPURLResponse?) -> ())? = nil) {
        guard let applicationId = user?.id else { callback?(nil, nil); return }
        let requestCallback: DiscordRequestCallback = { data, response, error in
            guard case let .object(command)? = JSON.jsonFromResponse(data: data, response: response) else {
                callback?(nil, response)
                return
            }

            callback?(DiscordApplicationCommand(commandObject: command), response)
        }
        let params = CommandParams(name: name, description: description, options: options)
        rateLimiter.executeRequest(endpoint: .guildApplicationCommands(applicationId: applicationId, guildId: guildId),
                                   token: token,
                                   requestInfo: .post(content: .json(JSON.encodeJSONData(params) ?? Data()), extraHeaders: nil),
                                   callback: requestCallback)
    }

    /// Default implementation
    func editApplicationCommand(_ commandId: CommandID,
                                on guildId: GuildID,
                                name: String,
                                description: String,
                                options: [DiscordApplicationCommandOption]? = nil,
                                callback: ((DiscordApplicationCommand?, HTTPURLResponse?) -> ())? = nil) {
        guard let applicationId = user?.id else { callback?(nil, nil); return }
        let requestCallback: DiscordRequestCallback = { data, response, error in
            guard case let .object(command)? = JSON.jsonFromResponse(data: data, response: response) else {
                callback?(nil, response)
                return
            }

            callback?(DiscordApplicationCommand(commandObject: command), response)
        }
        let params = CommandParams(name: name, description: description, options: options)
        rateLimiter.executeRequest(endpoint: .guildApplicationCommand(applicationId: applicationId, guildId: guildId, commandId: commandId),
                                   token: token,
                                   requestInfo: .patch(content: .json(JSON.encodeJSONData(params) ?? Data()), extraHeaders: nil),
                                   callback: requestCallback)
    }

    /// Default implementation
    func deleteApplicationCommand(_ commandId: CommandID,
                                  on guildId: GuildID,
                                  callback: ((HTTPURLResponse?) -> ())? = nil) {
        guard let applicationId = user?.id else { callback?(nil); return }
        let requestCallback: DiscordRequestCallback = { data, response, error in
            callback?(response)
        }
        rateLimiter.executeRequest(endpoint: .guildApplicationCommand(applicationId: applicationId, guildId: guildId, commandId: commandId),
                                   token: token,
                                   requestInfo: .delete(content: nil, extraHeaders: nil),
                                   callback: requestCallback)
    }
}
