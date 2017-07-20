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

import class Dispatch.DispatchSemaphore

/// Protocol that declares a type will be a Discord channel.
public protocol DiscordChannel : DiscordClientHolder {
    // MARK: Properties

    /// The id of the channel.
    var id: ChannelID { get }

    /// Whether or not the channel is private
    var isPrivate: Bool { get }
}

/// Protocol that declares a type will be a Discord text-based channel.
public protocol DiscordTextChannel : DiscordChannel {

    /// The snowflake id of the last received message on this channel.
    var lastMessageId: MessageID { get }
}

/// Represents the type of a channel.
public enum DiscordChannelType : Int {
    /// A text channel.
    case text

    /// A direct message channel.
    case direct

    /// A voice channel.
    case voice

    /// A GroupDM.
    case groupDM
}

public extension DiscordChannel {
    // MARK: Properties

    /// - returns: The guild that this channel is associated with. Or nil if this channel has no guild.
    public var guild: DiscordGuild? {
        return client?.guildForChannel(id)
    }

    // MARK: Methods

    /**
        Deletes this channel.
    */
    public func delete() {
        guard let client = self.client else { return }

        DefaultDiscordLogger.Logger.log("Deleting channel: \(id)", type: "DiscordChannel")

        client.deleteChannel(id)
    }

    /**
        Modifies this channel with `options`.

        - parameter options: An array of `DiscordEndpointOptions.ModifyChannel`
    */
    public func modifyChannel(options: [DiscordEndpoint.Options.ModifyChannel]) {
        guard let client = self.client else { return }

        client.modifyChannel(id, options: options)
    }


}

public extension DiscordTextChannel {
    // MARK: Text Channel Methods

    /**
     Pins a message to this channel.

     - parameter message: The message to pin
     */
    public func pinMessage(_ message: DiscordMessage) {
        guard let client = self.client else { return }

        client.addPinnedMessage(message.id, on: id)
    }

    /**
        Deletes a message from this channel.

        - parameter message: The message to delete
    */
    public func deleteMessage(_ message: DiscordMessage) {
        guard let client = self.client else { return }

        client.deleteMessage(message.id, on: id)
    }

    /**
        Gets the pinned messages for this channel.

        **NOTE**: This is a blocking method. If you need an async method, use the `.getPinnedMessages` from
        `DiscordEndpointConsumer` which is available on `DiscordClient`.

        - returns: An Array of pinned messages
    */
    public func getPinnedMessages() -> [DiscordMessage] {
        guard let client = self.client else { return [] }

        let lock = DispatchSemaphore(value: 0)

        var messages: [DiscordMessage]!

        client.getPinnedMessages(for: id) {pins in
            messages = pins

            lock.signal()
        }

        lock.wait()

        return messages
    }

    /**
        Sends a message to this channel. Can be used to send embeds and files as well.

        ```swift
        channel.send("This is just a simple message")
        ```

        Sending a message with an embed:

        ```swift
        channel.send(DiscordMessage(content: "This message also comes with an embed", embeds: [embed]))
        ```

        Sending a fully loaded message:

         ```swift
        channel.send(DiscordMessage(content: "This message has it all", embeds: [embed], files: [file]))
        ```

        - parameter message: The message to send.
    */
    public func send(_ message: DiscordMessage) {
        guard let client = self.client else { return }

        client.sendMessage(message, to: id)
    }

    /**
        Sends that this user is typing on this channel.
    */
    public func triggerTyping() {
        guard let client = self.client else { return }

        client.triggerTyping(on: id)
    }

    /**
        Unpins a message from this channel.

        - parameter message: The message to unpin.
    */
    public func unpinMessage(_ message: DiscordMessage) {
        guard let client = self.client else { return }

        client.deletePinnedMessage(message.id, on: id)
    }
}

func channelFromObject(_ object: [String: Any], withClient client: DiscordClient?) -> DiscordChannel? {
    guard let type = DiscordChannelType(rawValue: object.get("type", or: -1)) else { return nil }

    switch type {
    case .text:     return DiscordGuildTextChannel(guildChannelObject: object, client: client)
    case .voice:    return DiscordGuildVoiceChannel(guildChannelObject: object, client: client)
    case .direct:   return DiscordDMChannel(dmReadyObject: object, client: client)
    case .groupDM:  return DiscordGroupDMChannel(dmReadyObject: object, client: client)
    }
}

func privateChannelsFromArray(_ channels: [[String: Any]], client: DiscordClient) -> [ChannelID: DiscordTextChannel] {
    var channelDict = [ChannelID: DiscordTextChannel]()

    for channel in channels {
        guard let channel = channelFromObject(channel, withClient: client) as? DiscordTextChannel else { continue }

        channelDict[channel.id] = channel
    }

    return channelDict
}
