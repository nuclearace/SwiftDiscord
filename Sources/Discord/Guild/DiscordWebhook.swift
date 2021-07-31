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

import Foundation

/// Represents a webhook.
public struct DiscordWebhook: Identifiable, Codable, Hashable {
    public enum CodingKeys: String, CodingKey {
        case avatar
        case channelId = "channel_id"
        case guildId = "guild_id"
        case id
        case name
        case token
        case user
    }

    // MARK: Properties

    /// The avatar of this webhook.
    public let avatar: String?

    /// The snowflake for the channel this webhook is for.
    public let channelId: ChannelID

    /// The snowflake for of the guild this webhook is for, if for a guild.
    public let guildId: GuildID?

    /// The id of this webhook.
    public let id: WebhookID

    /// The default name of this webhook.
    public let name: String?

    /// The secure token for this webhook.
    public let token: String

    /// The user this webhook was created by (not present when the webhook was gotten by its token).
    public let user: DiscordUser?
}
