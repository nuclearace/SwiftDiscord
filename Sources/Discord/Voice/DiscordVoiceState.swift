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

/// Used to represent a user's voice connection status.
public struct DiscordVoiceState: Codable, Identifiable, Hashable {
    public enum CodingKeys: String, CodingKey {
        case guildId = "guild_id"
        case channelId = "channel_id"
        case userId = "user_id"
        case member
        case sessionId = "session_id"
        case deaf
        case mute
        case selfDeaf = "self_deaf"
        case selfMute = "self_mute"
        case selfStream = "self_stream"
        case selfVideo = "self_video"
        case suppress
        case requestToSpeakTimestamp = "request_to_speak_timestamp"
    }

    /// The guild id this voice state is for.
    public var guildId: GuildID?

    /// The channel id this user is connected to.
    public var channelId: ChannelID?

    /// The user id this voice state is for.
    public var userId: UserID

    /// The guild member this voice state is for.
    public var member: DiscordGuildMember?

    /// The session id for this voice state.
    public var sessionId: String?

    /// Whether the user is deafened by the server.
    public var deaf: Bool

    /// Whether the user is muted by the server.
    public var mute: Bool

    /// Whether the user is locally deafened.
    public var selfDeaf: Bool

    /// Whether the user is locally muted.
    public var selfMute: Bool

    /// Whether the user is streaming using 'Go Live'
    public var selfStream: Bool?

    /// Whether the user's camera is enabled.
    public var selfVideo: Bool

    /// Whether the user is muted by the current user.
    public var suppress: Bool

    /// The time at which the user requested to speak.
    public var requestToSpeakTimestamp: Date?

    public var id: UserID { userId }
}
