// The MIT License (MIT)
// Copyright (c) 2016 Erik Little
// Copyright (c) 2021 fwcd

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

/// An application using the Discord API.
public struct DiscordApplication: Codable {
    /// The id of the app.
    public var id: Snowflake

    /// The name of the app.
    public var name: String?

    /// The icon hash of the app.
    public var icon: String?

    /// The description of the app
    public var description: String?

    /// An array of RPC origin URLs, if enabled.
    public var rpcOrigins: [String]?

    /// Whether the bot can be joined by people other than the owner.
    public var botPublic: Bool?

    /// Whether the bot can only join upon completion of the full OAuth2 grant flow.
    public var botRequireCodeGrant: Bool?

    /// The URL of the app's ToS.
    public var termsOfServiceUrl: URL?

    /// The URL of the app's privacy policy.
    public var privacyPolicyUrl: URL?

    /// The owner of the application.
    public var owner: DiscordUser?

    /// A summary if this is a game sold on Discord.
    public var summary: String?

    /// Hex encoded key for verification in interactions.
    public var verifyKey: String?

    /// The guild ID if this is an app sold on Discord.
    public var guildId: GuildID?

    /// Game SKU for games sold on Discord.
    public var primarySkuId: Snowflake?

    /// URL slug linked to store page for games sold on Discord.
    public var slug: String?

    /// The cover image hash of an application.
    public var coverImage: String?

    /// The applications public flags.
    public var flags: DiscordApplicationFlags?
}

/// Public flags of an application.
public struct DiscordApplicationFlags: RawRepresentable, Codable, OptionSet {
    public var rawValue: UInt32

    public static let gatewayPresence = DiscordApplicationFlags(rawValue: 1 << 12)
    public static let gatewayPresenceLimited = DiscordApplicationFlags(rawValue: 1 << 13)
    public static let gatewayGuildMembers = DiscordApplicationFlags(rawValue: 1 << 14)
    public static let gatewayGuildMembersLimited = DiscordApplicationFlags(rawValue: 1 << 15)
    public static let verificationPendingGuildLimit = DiscordApplicationFlags(rawValue: 1 << 16)
    public static let embedded = DiscordApplicationFlags(rawValue: 1 << 17)

    public init(rawValue: UInt32) {
        self.rawValue = rawValue
    }
}
