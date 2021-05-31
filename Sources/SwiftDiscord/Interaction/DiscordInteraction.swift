import Foundation

/// Represents a slash-command invocation by the user.
public struct DiscordInteraction {
    // MARK: Properties

    /// ID of the interaction
    public let id: InteractionID

    /// Type of the interaction
    public let type: DiscordInteractionType?

    /// Command data payload
    /// Always specified for DiscordApplicationCommand interaction
    /// types, but optional for future-proofing.
    public let data: DiscordApplicationCommandInteractionData?

    /// The message a user interacted with, e.g. when pressing a button.
    public let message: DiscordMessage?

    /// Guild it was sent from
    public let guildId: GuildID

    /// Channel it was sent from
    public let channelId: ChannelID

    /// Guild member data for the invoking user
    public let member: DiscordGuildMember?

    /// Continuation token for responding to the interaction
    public let token: String

    /// Read-only property, always 1
    public let version: Int

    init(interactionObject: [String: Any]) {
        id = Snowflake(interactionObject["id"] as? String) ?? 0
        type = (interactionObject["type"] as? Int).flatMap(DiscordInteractionType.init(rawValue:))
        data = (interactionObject["data"] as? [String: Any]).map(DiscordApplicationCommandInteractionData.init(dataObject:))
        message = (interactionObject["message"] as? [String: Any]).map { DiscordMessage(messageObject: $0, client: nil) }
        let guildId = Snowflake(interactionObject["guild_id"] as? String) ?? 0
        self.guildId = guildId
        channelId = Snowflake(interactionObject["channel_id"] as? String) ?? 0
        member = (interactionObject["member"] as? [String: Any]).map { DiscordGuildMember(guildMemberObject: $0, guildId: guildId) }
        token = (interactionObject["token"] as? String) ?? ""
        version = (interactionObject["version"] as? Int) ?? 1
    }
}

public struct DiscordInteractionType: RawRepresentable, Hashable {
    public var rawValue: Int

    public static let ping = DiscordInteractionType(rawValue: 1)
    public static let applicationCommand = DiscordInteractionType(rawValue: 2)
    public static let messageComponent = DiscordInteractionType(rawValue: 3)

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
}
