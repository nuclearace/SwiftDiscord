import Foundation

public protocol DiscordClientSpec : class, DiscordEngineClient {
	var connected: Bool { get }
	var guilds: [String: DiscordGuild] { get }
	var handleQueue: DispatchQueue { get set }
	var isBot: Bool { get }
	var relationships: [[String: Any]] { get } // TODO make this a [DiscordRelationship]
	var token: String { get }
	var user: DiscordUser? { get }
	var voiceState: DiscordVoiceState? { get }

	init(token: String)

	func connect()
	func disconnect()
	func on(_ event: String, callback: @escaping ([Any]) -> Void)
	func handleEvent(_ event: String, with data: [Any])
	func joinVoiceChannel(_ channelId: String, callback: @escaping (String) -> Void)
	func leaveVoiceChannel(_ channelId: String)

	// REST API
	func addPinnedMessage(_ messageId: String, on channelId: String)
	func bulkDeleteMessages(_ messages: [String], on channelId: String)
	func createInvite(for channelId: String, options: [DiscordEndpointOptions.CreateInvite],
		callback: @escaping (DiscordInvite?) -> Void)
	func createGuildChannel(on guildId: String, options: [DiscordEndpointOptions.GuildCreateChannel])
	func deleteChannel(_ channelId: String)
	func deleteChannelPermission(_ overwriteId: String, on channelId: String)
	func deleteGuild(_ guildId: String)
	func deleteMessage(_ messageId: String, on channelId: String)
	func deletePinnedMessage(_ messageId: String, on channelId: String)
	func editMessage(_ messageId: String, on channelId: String, content: String)
	func editChannelPermission(_ permissionOverwrite: DiscordPermissionOverwrite, on channelId: String)
	func getBotURL(with permissions: [DiscordPermission]) -> URL?
	func getChannel(_ channelId: String, callback: @escaping (DiscordGuildChannel?) -> Void)
	func getGuildChannels(_ guildId: String, callback: @escaping ([DiscordGuildChannel]) -> Void)
	func getGuildMember(by id: String, on guildId: String, callback: @escaping (DiscordGuildMember?) -> Void)
	func getInvites(for channelId: String, callback: @escaping ([DiscordInvite]) -> Void)
	func getMessages(for channel: String, options: [DiscordEndpointOptions.GetMessage],
		callback: @escaping ([DiscordMessage]) -> Void)
	func getPinnedMessages(for channelId: String, callback: @escaping ([DiscordMessage]) -> Void)
	func modifyChannel(_ channelId: String, options: [DiscordEndpointOptions.ModifyChannel])
	func modifyGuild(_ guildId: String, options: [DiscordEndpointOptions.ModifyGuild])
	func modifyGuildChannelPosition(on guildId: String, channelId: String, position: Int)
	func sendMessage(_ message: String, to channelId: String, tts: Bool)
	func triggerTyping(on channelId: String)
}
