/// An intent defines the events the gateway should
/// subscribe to.
///
/// See https://discord.com/developers/docs/topics/gateway#gateway-intents
public struct DiscordGatewayIntents: OptionSet, RawRepresentable, Codable {
    public let rawValue: Int

    /// Creation, updates and deletions of guilds, roles and channels.
    public static let guilds = DiscordGatewayIntents(rawValue: 1 << 0)
    /// Guild member update events. This is a privileged intent.
    public static let guildMembers = DiscordGatewayIntents(rawValue: 1 << 1)
    /// Guild ban and unban events.
    public static let guildBans = DiscordGatewayIntents(rawValue: 1 << 2)
    /// Guild emoji update events.
    public static let guildEmojis = DiscordGatewayIntents(rawValue: 1 << 3)
    /// Guild integration update events.
    public static let guildIntegrations = DiscordGatewayIntents(rawValue: 1 << 4)
    /// Guild webhook update events.
    public static let guildWebhooks = DiscordGatewayIntents(rawValue: 1 << 5)
    /// Guild invite events.
    public static let guildInvites = DiscordGatewayIntents(rawValue: 1 << 6)
    /// Guild voice state update events.
    public static let guildVoiceStates = DiscordGatewayIntents(rawValue: 1 << 7)
    /// Guild presence update events. This is a privileged intent.
    public static let guildPresences = DiscordGatewayIntents(rawValue: 1 << 8)
    /// Guild message creations, updates and deletions.
    public static let guildMessages = DiscordGatewayIntents(rawValue: 1 << 9)
    /// Guild message reaction creations, updates and deletions.
    public static let guildMessageReactions = DiscordGatewayIntents(rawValue: 1 << 10)
    /// Guild typing indicators.
    public static let guildMessageTyping = DiscordGatewayIntents(rawValue: 1 << 11)
    /// Direct message creations, updates and deletions.
    public static let directMessages = DiscordGatewayIntents(rawValue: 1 << 12)
    /// Direct message reaction creations, updates and deletions.
    public static let directMessageReactions = DiscordGatewayIntents(rawValue: 1 << 13)
    /// Direct message typing indicators.
    public static let directMessageTyping = DiscordGatewayIntents(rawValue: 1 << 14)

    /// The privileged intents (which may require enabling in the Discord developer console).
    public static let privilegedIntents: DiscordGatewayIntents = [
        .guildMembers,
        .guildPresences
    ]

    /// The unprivileged intents. Use these if you don't need the privileged intents.
    public static let unprivilegedIntents: DiscordGatewayIntents = [
        .guilds,
        .guildBans,
        .guildEmojis,
        .guildIntegrations,
        .guildWebhooks,
        .guildInvites,
        .guildVoiceStates,
        .guildMessages,
        .guildMessageReactions,
        .guildMessageTyping,
        .directMessages,
        .directMessageReactions,
        .directMessageTyping
    ]

    /// All intents.
    public static let allIntents: DiscordGatewayIntents = [
        .privilegedIntents,
        .unprivilegedIntents
    ]

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
}
