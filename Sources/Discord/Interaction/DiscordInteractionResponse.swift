import Foundation

public struct DiscordInteractionResponse: Encodable {
    // MARK: Properties

    /// The type of response
    public let type: DiscordInteractionResponseType

    /// An optional response message
    public let data: DiscordInteractionApplicationCommandCallbackData?

    public init(
        type: DiscordInteractionResponseType,
        data: DiscordInteractionApplicationCommandCallbackData? = nil
    ) {
        self.type = type
        self.data = data
    }
}

public enum DiscordInteractionResponseType: Int, Encodable {
    /// Ack a ping
    case pong = 1

    /// Ack a command without sending a message, eating the user's input
    case acknowledge = 2

    /// Respond with a message, eating the user's input
    case channelMessage = 3

    /// Respond with a message, showing the user's input
    case channelMessageWithSource = 4

    /// Ack a command without sending a message, showing the user's input
    case ackWithSource = 5

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}

public struct DiscordInteractionApplicationCommandCallbackData: Encodable {
    public enum CodingKeys: String, CodingKey {
        case tts
        case content
        case embeds
        case allowedMentions = "allowed_mentions"
    }

    public let tts: Bool?
    public let content: String?
    public let embeds: [DiscordEmbed]?
    public let allowedMentions: DiscordAllowedMentions?

    public init(
        tts: Bool? = nil,
        content: String? = nil,
        embeds: [DiscordEmbed]? = nil,
        allowedMentions: DiscordAllowedMentions? = nil
    ) {
        self.tts = tts
        self.content = content
        self.embeds = embeds
        self.allowedMentions = allowedMentions
    }
}
