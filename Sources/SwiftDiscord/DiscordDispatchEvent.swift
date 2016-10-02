public enum DiscordDispatchEvent : String {
	case ready = "READY"

	// Messaging
	case messageCreate = "MESSAGE_CREATE"
	case messageDelete = "MESSAGE_DELETE"
	case messageDeleteBulk = "MESSAGE_DELETE_BULK"
	case messageUpdate = "MESSAGE_UPDATE"
}
