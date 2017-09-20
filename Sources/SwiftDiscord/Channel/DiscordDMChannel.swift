// The MIT License (MIT)
// Copyright (c) 2016 Erik Little

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
public struct DiscordDMChannel : DiscordTextChannel {
    // MARK: Properties

    /// The snowflake id of the channel.
    public let id: ChannelID

    /// The user this channel is with.
    public let recipient: DiscordUser

    /// Reference to the client.
    public weak var client: DiscordClient?

    /// The snowflake id of the last received message on this channel.
    public var lastMessageId: MessageID

    init(dmObject: [String: Any]) {
        recipient = DiscordUser(userObject: dmObject.get("recipient", or: [String: Any]()))
        id = Snowflake(dmObject["id"] as? String) ?? 0
        lastMessageId = Snowflake(dmObject["last_message_id"] as? String) ?? 0
    }

    init(dmReadyObject: [String: Any], client: DiscordClient? = nil) {
        recipient = DiscordUser(userObject: dmReadyObject.get("recipients", or: JSONArray())[0])
        id = Snowflake(dmReadyObject["id"] as? String) ?? 0
        lastMessageId = Snowflake(dmReadyObject["last_message_id"] as? String) ?? 0
        self.client = client
    }

    static func DMsfromArray(_ dmArray: [[String: Any]]) -> [ChannelID: DiscordDMChannel] {
        var dms = [ChannelID: DiscordDMChannel]()

        for dm in dmArray {
            let dmChannel = DiscordDMChannel(dmObject: dm)

            dms[dmChannel.id] = dmChannel
        }

        return dms
    }
}

/// Represents a direct message channel with a group of users.
public struct DiscordGroupDMChannel : DiscordTextChannel {
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

    init(dmReadyObject: [String: Any], client: DiscordClient? = nil) {
        recipients = dmReadyObject.get("recipients", or: JSONArray()).map(DiscordUser.init)
        id = dmReadyObject.getSnowflake()
        lastMessageId = Snowflake(dmReadyObject["last_message_id"] as? String) ?? 0
        name = dmReadyObject["name"] as? String
        self.client = client
    }
}
