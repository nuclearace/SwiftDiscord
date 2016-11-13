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

public struct DiscordVoiceState {
	public let channelId: String
	public let guildId: String
	public let sessionId: String
	public let userId: String

	public var deaf: Bool
	public var mute: Bool
	public var selfDeaf: Bool
	public var selfMute: Bool
	public var suppress: Bool
}

extension DiscordVoiceState {
	init(voiceStateObject: [String: Any], guildId: String) {
		let channelId = voiceStateObject.get("channel_id", or: "")
		let sessionId = voiceStateObject.get("session_id", or: "")
		let userId = voiceStateObject.get("user_id", or: "")
		let deaf = voiceStateObject.get("deaf", or: false)
		let mute = voiceStateObject.get("mute", or: false)
		let selfDeaf = voiceStateObject.get("self_deaf", or: false)
		let selfMute = voiceStateObject.get("self_mute", or: false)
		let suppress = voiceStateObject.get("suppress", or: false)

		self.init(channelId: channelId, guildId: guildId, sessionId: sessionId, userId: userId, deaf: deaf, mute: mute,
			selfDeaf: selfDeaf, selfMute: selfMute, suppress: suppress)
	}

	static func voiceStatesFromArray(_ voiceStateArray: [[String: Any]], guildId: String) -> [String: DiscordVoiceState] {
		var voiceStates = [String: DiscordVoiceState]()

		for voiceState in voiceStateArray {
			let voiceState = DiscordVoiceState(voiceStateObject: voiceState, guildId: guildId)

			voiceStates[voiceState.userId] = voiceState
		}

		return voiceStates
	}
}
