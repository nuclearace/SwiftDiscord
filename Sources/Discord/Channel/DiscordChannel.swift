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
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import Logging

import class Dispatch.DispatchSemaphore

fileprivate let logger = Logger(label: "DiscordChannel")

/// A Discord channel of unspecified type.
public enum DiscordChannel: DiscordClientHolder, Codable, Identifiable {
    case text(DiscordGuildTextChannel)
    case direct(DiscordDMChannel)
    case voice(DiscordGuildVoiceChannel)
    case groupDM(DiscordGroupDMChannel)
    case category(DiscordGuildChannelCategory)

    public enum CodingKeys: String, CodingKey {
        case type
    }

    // TODO: Others

    /// The snowflake id of the channel.
    public var id: ChannelID {
        switch self {
        case .text(let channel): return channel.id
        case .direct(let channel): return channel.id
        case .voice(let channel): return channel.id
        case .groupDM(let channel): return channel.id
        case .category(let channel): return channel.id
        }
    }

    public var client: DiscordClient? {
        switch self {
        case .text(let channel): return channel.client
        case .direct(let channel): return channel.client
        case .voice(let channel): return channel.client
        case .groupDM(let channel): return channel.client
        case .category(let channel): return channel.client
        }
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(DiscordChannelType.self, forKey: .type)

        switch type {
        case .text: self = .text(try DiscordGuildTextChannel(from: decoder))
        case .direct: self = .direct(try DiscordDMChannel(from: decoder))
        case .voice: self = .voice(try DiscordGuildVoiceChannel(from: decoder))
        case .groupDM: self = .groupDM(try DiscordGroupDMChannel(from: decoder))
        case .category: self = .category(try DiscordGuildChannelCategory(from: decoder))
        }
    }
}

/// Protocol that declares a type will be a Discord text-based channel.
public protocol DiscordTextChannel {
    // MARK: Properties

    /// The snowflake id of the last received message on this channel.
    var lastMessageId: MessageID { get }
}

/// Represents the type of a channel.
public enum DiscordChannelType: Int, Codable {
    /// A guild text channel.
    case text = 0

    /// A direct message channel.
    case direct = 1

    /// A voice channel within a guild.
    case voice = 2

    /// A group direct message.
    case groupDM = 3

    /// An organizational category in a guild that contains up to 50 channels.
    case category = 4

    /// A channel that users can follow in their own guild.
    case news = 5

    /// A channel in which game devs can sell their games on Discord.
    case store = 6

    /// A temporary sub-channel in a guild news channel.
    case newsThread = 10

    /// A temporary sub-channel within a guild text channel.
    case publicThread = 11

    /// A temporary sub-channel in a guild text channel that is only viewable
    /// by those invited and those with the 'manage threads' permission.
    case privateThread = 12

    /// A guild voice channel for hosting events with an audience.
    case stageVoice = 13
}

public extension DiscordChannel {
    // MARK: Properties

    /// - returns: The guild that this channel is associated with. Or nil if this channel has no guild.
    var guild: DiscordGuild? {
        return client?.guildForChannel(id)
    }

    // MARK: Methods

    ///
    /// Deletes this channel.
    ///
    func delete(reason: String? = nil) {
        guard let client = self.client else { return }

        logger.info("Deleting channel: \(id)")

        client.deleteChannel(id, reason: reason)
    }

    ///
    /// Modifies this channel with `options`.
    ///
    /// - parameter options: An array of `DiscordEndpointOptions.ModifyChannel`
    ///
    func modifyChannel(options: [DiscordEndpoint.Options.ModifyChannel], reason: String? = nil) {
        guard let client = self.client else { return }

        client.modifyChannel(id, options: options, reason: reason)
    }
}

public extension DiscordTextChannel {
    // MARK: Text Channel Methods

    ///
    /// Pins a message to this channel.
    ///
    /// - parameter message: The message to pin
    ///
    func pinMessage(_ message: DiscordMessage) {
        guard let client = self.client else { return }

        client.addPinnedMessage(message.id, on: id)
    }

    ///
    /// Deletes a message from this channel.
    ///
    /// - parameter message: The message to delete
    ///
    func deleteMessage(_ message: DiscordMessage) {
        guard let client = self.client else { return }

        client.deleteMessage(message.id, on: id)
    }

    ///
    /// Gets the pinned messages for this channel.
    ///
    /// - parameter callback: The callback.
    ///
    func getPinnedMessages(callback: @escaping ([DiscordMessage], HTTPURLResponse?) -> ()) {
        guard let client = self.client else { return callback([], nil) }

        client.getPinnedMessages(for: id) {pins, response in
            callback(pins, response)
        }
    }

    ///
    /// Sends a message to this channel. Can be used to send embeds and files as well.
    ///
    /// ```swift
    /// channel.send("This is just a simple message")
    /// ```
    ///
    /// Sending a message with an embed:
    ///
    /// ```swift
    /// channel.send(DiscordMessage(content: "This message also comes with an embed", embeds: [embed]))
    /// ```
    ///
    /// Sending a fully loaded message:
    ///
    /// ```swift
    /// channel.send(DiscordMessage(content: "This message has it all", embeds: [embed], files: [file]))
    /// ```
    ///
    /// - parameter message: The message to send.
    ///
    func send(_ message: DiscordMessage) {
        guard let client = self.client else { return }

        client.sendMessage(message, to: id)
    }

    ///
    /// Sends that this user is typing on this channel.
    ///
    func triggerTyping() {
        guard let client = self.client else { return }

        client.triggerTyping(on: id)
    }

    ///
    /// Unpins a message from this channel.
    ///
    /// - parameter message: The message to unpin.
    ///
    func unpinMessage(_ message: DiscordMessage) {
        guard let client = self.client else { return }

        client.deletePinnedMessage(message.id, on: id)
    }
}
