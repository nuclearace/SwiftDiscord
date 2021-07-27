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

/// Represents a voice state.
public struct DiscordVoiceState: Codable, Identifiable {
    public enum CodingKeys: String, CodingKey {
        case channelId = "channel_id"
        case sessionId = "session_id"
        case userId = "user_id"
        case deaf
        case mute
        case selfDeaf = "self_deaf"
        case selfMute = "self_mute"
        case suppress
    }

    // MARK: Properties

    /// The snowflake id of the voice channel this state belongs to.
    public let channelId: ChannelID

    /// Whether this user is deafened.
    public let deaf: Bool

    /// Whether this user is muted.
    public let mute: Bool

    /// Whether this user has deafened themself.
    public let selfDeaf: Bool

    /// Whether this user has muted themself.
    public let selfMute: Bool

    /// The session id that this state belongs to.
    public let sessionId: String

    /// Whether this user is being suppressed.
    public let suppress: Bool

    /// The snowflake id of the user this state is for.
    public let userId: UserID

    /// Alias for `userId` to permit usage in `DiscordIDDictionary`s.
    public var id: UserID { userId }
}
