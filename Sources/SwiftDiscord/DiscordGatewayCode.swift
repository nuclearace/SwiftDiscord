public enum DiscordGatewayCode {
	case gateway(DiscordNormalGatewayCode)
	case voice(DiscordVoiceGatewayCode)

	var rawCode: Int {
		switch self {
		case let .gateway(gatewayCode):
			return gatewayCode.rawValue
		case let .voice(voiceCode):
			return voiceCode.rawValue
		}
	}
}

public enum DiscordNormalGatewayCode : Int {
	case dispatch
	case heartbeat
	case identify
	case statusUpdate
	case voiceStatusUpdate
	case voiceServerPing
	case resume
	case reconnect
	case requestGuildMembers
	case invalidSession
	case hello
	case heartbeatAck
}

public enum DiscordVoiceGatewayCode : Int {
	case identify
	case selectProtocol
	case ready
	case heartbeat
	case sessionDescription
	case speaking
}
