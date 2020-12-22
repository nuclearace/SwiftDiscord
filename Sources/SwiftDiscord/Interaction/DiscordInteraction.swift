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
        let guildId = Snowflake(interactionObject["guild_id"] as? String) ?? 0
        self.guildId = guildId
        channelId = Snowflake(interactionObject["channel_id"] as? String) ?? 0
        member = (interactionObject["member"] as? [String: Any]).map { DiscordGuildMember(guildMemberObject: $0, guildId: guildId) }
        token = (interactionObject["token"] as? String) ?? ""
        version = (interactionObject["version"] as? Int) ?? 1
    }
}

public enum DiscordInteractionType: Int {
    case ping = 1
    case DiscordapplicationCommand = 2
}
