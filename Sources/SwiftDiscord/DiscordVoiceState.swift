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
		let channelId = voiceStateObject["channel_id"] as? String ?? ""
		let sessionId = voiceStateObject["session_id"] as? String ?? ""
		let userId = voiceStateObject["user_id"] as? String ?? ""
		let deaf = voiceStateObject["deaf"] as? Bool ?? false
		let mute = voiceStateObject["mute"] as? Bool ?? false
		let selfDeaf = voiceStateObject["self_deaf"] as? Bool ?? false
		let selfMute = voiceStateObject["self_mute"] as? Bool ?? false
		let suppress = voiceStateObject["suppress"] as? Bool ?? false

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
