/// An intent defines the events the gateway should
/// subscribe to.
///
/// See https://discord.com/developers/docs/topics/gateway#gateway-intents
public struct DiscordGatewayIntent : OptionSet {
    public let rawValue: Int

    /// Creation, updates and deletions of guilds, roles and channels.
    public static let guilds = DiscordGatewayIntent(rawValue: 1 << 0)
    /// Guild member update events. This is a privileged intent.
    public static let guildMembers = DiscordGatewayIntent(rawValue: 1 << 1)
    /// Guild ban and unban events.
    public static let guildBans = DiscordGatewayIntent(rawValue: 1 << 2)
    /// Guild emoji update events.
    public static let guildEmojis = DiscordGatewayIntent(rawValue: 1 << 3)
    /// Guild integration update events.
    public static let guildIntegrations = DiscordGatewayIntent(rawValue: 1 << 4)
    /// Guild webhook update events.
    public static let guildWebhooks = DiscordGatewayIntent(rawValue: 1 << 5)
    /// Guild invite events.
    public static let guildInvites = DiscordGatewayIntent(rawValue: 1 << 6)
    /// Guild voice state update events.
    public static let guildVoiceStates = DiscordGatewayIntent(rawValue: 1 << 7)
    /// Guild presence update events. This is a privileged intent.
    public static let guildPresences = DiscordGatewayIntent(rawValue: 1 << 8)
    /// Guild message creations, updates and deletions.
    public static let guildMessages = DiscordGatewayIntent(rawValue: 1 << 9)
    /// Guild message reaction creations, updates and deletions.
    public static let guildMessageReactions = DiscordGatewayIntent(rawValue: 1 << 10)
    /// Guild typing indicators.
    public static let guildMessageTyping = DiscordGatewayIntent(rawValue: 1 << 11)
    /// Direct message creations, updates and deletions.
    public static let directMessages = DiscordGatewayIntent(rawValue: 1 << 12)
    /// Direct message reaction creations, updates and deletions.
    public static let directMessageReactions = DiscordGatewayIntent(rawValue: 1 << 13)
    /// Direct message typing indicators.
    public static let directMessageTyping = DiscordGatewayIntent(rawValue: 1 << 14)

    /// The privileged intents (which may require enabling in the Discord developer console).
    public static let privilegedIntents: DiscordGatewayIntent = [
        .guildMembers,
        .guildPresences
    ]

    /// The unprivileged intents. Use these if you don't need the privileged intents.
    public static let unprivilegedIntents: DiscordGatewayIntent = [
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
    public static let allIntents: DiscordGatewayIntent = [
        .privilegedIntents,
        .unprivilegedIntents
    ]

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
}
