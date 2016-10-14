public enum DiscordDispatchEvent : String {
	case ready = "READY"

	// Messaging
	case messageCreate = "MESSAGE_CREATE"
	case messageDelete = "MESSAGE_DELETE"
	case messageDeleteBulk = "MESSAGE_DELETE_BULK"
	case messageUpdate = "MESSAGE_UPDATE"

	// Guilds
	case guildBanAdd = "GUILD_BAN_ADD"
	case guildBanRemove = "GUILD_BAN_REMOVE"
	case guildCreate = "GUILD_CREATE"
	case guildDelete = "GUILD_DELETE"
	case guildEmojisUpdate = "GUILD_EMOJIS_UPDATE"
	case guildIntegrationsUpdate = "GUILD_INTEGRATIONS_UPDATE"
	case guildMemberAdd = "GUILD_MEMBER_ADD"
	case guildMemberRemove = "GUILD_MEMBER_REMOVE"
	case guildMemberUpdate = "GUILD_MEMBER_UPDATE"
	case guildMembersChunk = "GUILD_MEMBERS_CHUNK"
	case guildRoleCreate = "GUILD_ROLE_CREATE"
	case guildRoleDelete = "GUILD_ROLE_DELETE"
	case guildRoleUpdate = "GUILD_ROLE_UPDATE"
	case guildUpdate = "GUILD_UPDATE"

	// Voice
	case voiceServerUpdate = "VOICE_SERVER_UPDATE"
	case voiceStateUpdate = "VOICE_STATE_UPDATE"

	case presenceUpdate = "PRESENCE_UPDATE"

	case typingStart = "TYPING_START"
}
