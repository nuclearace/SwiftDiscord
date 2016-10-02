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
