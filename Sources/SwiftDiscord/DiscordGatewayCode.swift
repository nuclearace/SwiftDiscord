public enum DiscordGatewayCode : Int {
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