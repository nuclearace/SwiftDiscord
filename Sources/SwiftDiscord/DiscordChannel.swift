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

/// Protocol that declares a type will be a Discord channel.
public protocol DiscordChannel : DiscordClientHolder {
    // MARK: Properties

    /// The id of the channel.
    var id: String { get }

    /// The type of the channel
    var type: DiscordChannelType { get }
}

public extension DiscordChannel {
    // MARK: Properties

    /// - returns: The guild that this channel is associated with. Or nil if this channel has no guild.
    var guild: DiscordGuild? {
        return client?.guildForChannel(id)
    }

    // MARK: Methods

    /**
        Deletes a message from this channel.

        - parameter message: The message to delete
    */
    func deleteMessage(_ message: DiscordMessage) {
        guard let client = self.client else { return }

        client.deleteMessage(message.id, on: id)
    }

    /**
        Gets the pinned messages for this channel.

        **NOTE**: This is a blocking method. If you need an async method, use the `.getPinnedMessages` from
        `DiscordEndpointConsumer` which is available on `DiscordClient`.

        - returns: An Array of pinned messages
    */
    func getPinnedMessages() -> [DiscordMessage] {
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
        Modifies this channel with `options`.

        - parameter options: An array of `DiscordEndpointOptions.ModifyChannel`
    */
    func modifyChannel(options: [DiscordEndpointOptions.ModifyChannel]) {
        guard let client = self.client else { return }

        client.modifyChannel(id, options: options)
    }

    /**
        Sends a file to this channel.

        - parameter file: A `DiscordFileUpload` to upload
        - parameter content: An optional message for this upload
        - parameter tts: Whether the message is TTS
    */
    func sendFile(_ file: DiscordFileUpload, content: String = "", tts: Bool = false) {
        guard let client = self.client, type != .voice else { return }

        client.sendFile(file, content: content, to: id, tts: tts)
    }

    /**
        Sends a message to this channel.

        - parameter content: An optional message for this upload
        - parameter tts: Whether the message is TTS
    */
    func sendMessage(_ content: String, tts: Bool = false) {
        guard let client = self.client, type != .voice else { return }

        client.sendMessage(content, to: id, tts: tts)
    }

    /**
        Sends that this user is typing on this channel.
    */
    func triggerTyping() {
        guard let client = self.client else { return }

        client.triggerTyping(on: id)
    }
}

func channelFromObject(_ object: [String: Any]) -> DiscordChannel? {
    guard let type = DiscordChannelType(rawValue: object.get("type", or: -1)) else { return nil }

    switch type {
    case .text:     fallthrough
    case .voice:    return DiscordGuildChannel(guildChannelObject: object)
    case .direct:   return DiscordDMChannel(dmReadyObject: object)
    case .groupDM:  return DiscordGroupDMChannel(dmReadyObject: object)
    }
}

func privateChannelsFromArray(_ channels: [[String: Any]]) -> [String: DiscordChannel] {
    var channelDict = [String: DiscordChannel]()

    for case let channel? in channels.map(channelFromObject) {
        channelDict[channel.id] = channel
    }

    return channelDict
}
