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

/// Represents a direct message channel with another user.
public struct DiscordDMChannel: DiscordTextChannel, DiscordClientHolder, Identifiable, Codable {
    public enum CodingKeys: String, CodingKey {
        case recipient
        case id
        case lastMessageId = "last_message_id"
    }

    // MARK: Properties

    /// The snowflake id of the channel.
    public let id: ChannelID

    /// The users this channel is with.
    public let recipients: [DiscordUser]

    /// Reference to the client.
    public weak var client: DiscordClient?

    /// The snowflake id of the last received message on this channel.
    public var lastMessageId: MessageID
}

/// Represents a direct message channel with a group of users.
public struct DiscordGroupDMChannel: DiscordTextChannel, DiscordClientHolder, Identifiable {
    public enum CodingKeys: String, CodingKey {
        case id
        case recipients
        case lastMessageId = "last_message_id"
        case name
    }

    // MARK: Properties

    /// The snowflake id of the channel.
    public let id: ChannelID

    /// The users in this channel.
    public let recipients: [DiscordUser]

    /// Reference to the client.
    public weak var client: DiscordClient?

    /// The snowflake id of the last received message on this channel.
    public var lastMessageId: MessageID

    /// The name of this group dm.
    public var name: String?
}
