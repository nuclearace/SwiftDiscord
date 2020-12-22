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
    func createInteractionResponse(for interactionId: InteractionID,
                                   token interactionToken: String,
                                   response: DiscordMessage,
                                   callback: ((HTTPURLResponse?) -> ())? = nil){
        let requestCallback: DiscordRequestCallback = { data, response, error in
            callback?(response)
        }
        let requestInfo: DiscordEndpoint.EndpointRequest

        switch response.createDataForSending() {
        case let .left(data):
            requestInfo = .post(content: .json(data), extraHeaders: nil)
        case let .right((boundary, body)):
            requestInfo = .post(content: .other(type: "multipart/form-data; boundary=\(boundary)", body: body),
                                extraHeaders: nil)
        }

        rateLimiter.executeRequest(endpoint: .interactionsCallback(interactionId: interactionId, interactionToken: interactionToken),
                                   token: token,
                                   requestInfo: requestInfo,
                                   callback: requestCallback)
    }
}
