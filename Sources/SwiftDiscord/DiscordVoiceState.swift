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

/// Represents a voice state.
public struct DiscordVoiceState {
    // MARK: Properties

    /// The snowflake id of the voice channel this state belongs to.
    public let channelId: ChannelID

    /// Whether this user is deafened.
    public let deaf: Bool

    /// The snowflake id of the guild this state belongs to.
    public let guildId: GuildID

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

    init(voiceStateObject: [String: Any], guildId: GuildID) {
        self.guildId = guildId
        channelId = Snowflake(voiceStateObject["channel_id"] as? String) ?? 0
        sessionId = voiceStateObject.get("session_id", or: "")
        userId = Snowflake(voiceStateObject["user_id"] as? String) ?? 0
        deaf = voiceStateObject.get("deaf", or: false)
        mute = voiceStateObject.get("mute", or: false)
        selfDeaf = voiceStateObject.get("self_deaf", or: false)
        selfMute = voiceStateObject.get("self_mute", or: false)
        suppress = voiceStateObject.get("suppress", or: false)
    }

    static func voiceStatesFromArray(_ voiceStateArray: [[String: Any]], guildId: GuildID) -> [UserID: DiscordVoiceState] {
        var voiceStates = [UserID: DiscordVoiceState]()

        for voiceState in voiceStateArray {
            let voiceState = DiscordVoiceState(voiceStateObject: voiceState, guildId: guildId)

            voiceStates[voiceState.userId] = voiceState
        }

        return voiceStates
    }
}
