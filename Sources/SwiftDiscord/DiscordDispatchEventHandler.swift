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

public protocol DiscordDispatchEventHandler : DiscordClientSpec {
	func handleChannelCreate(with data: [String: Any])
	func handleChannelDelete(with data: [String: Any])
	func handleChannelUpdate(with data: [String: Any])
	func handleDispatch(event: DiscordDispatchEvent, data: DiscordGatewayPayloadData)
	func handleGuildEmojiUpdate(with data: [String: Any])
	func handleGuildMemberAdd(with data: [String: Any])
	func handleGuildMemberRemove(with data: [String: Any])
	func handleGuildMemberUpdate(with data: [String: Any])
	func handleGuildMembersChunk(with data: [String: Any])
	func handleGuildRoleCreate(with data: [String: Any])
	func handleGuildRoleRemove(with data: [String: Any])
	func handleGuildRoleUpdate(with data: [String: Any])
	func handleGuildCreate(with data: [String: Any])
	func handleGuildDelete(with data: [String: Any])
	func handleGuildUpdate(with data: [String: Any])
	func handlePresenceUpdate(with data: [String: Any])
	func handleReady(with data: [String: Any])
	func handleVoiceServerUpdate(with data: [String: Any])
	func handleVoiceStateUpdate(with data: [String: Any])
}

public extension DiscordDispatchEventHandler {
	func handleDispatch(event: DiscordDispatchEvent, data: DiscordGatewayPayloadData) {
		switch (event, data) {
		case let (.presenceUpdate, .object(data)):	handlePresenceUpdate(with: data)
		case let (.messageCreate, .object(data)):	handleEvent("messageCreate", with: [DiscordMessage(messageObject: data)])
		case let (.guildMemberAdd, .object(data)):	handleGuildMemberAdd(with: data)
		case let (.guildMembersChunk, .object(data)):	handleGuildMembersChunk(with: data)
		case let (.guildMemberUpdate, .object(data)):	handleGuildMemberUpdate(with: data)
		case let (.guildMemberRemove, .object(data)):	handleGuildMemberRemove(with: data)
		case let (.guildRoleCreate, .object(data)):	handleGuildRoleCreate(with: data)
		case let (.guildRoleDelete, .object(data)):	handleGuildRoleRemove(with: data)
		case let (.guildRoleUpdate, .object(data)):	handleGuildRoleUpdate(with: data)
		case let (.guildCreate, .object(data)):	handleGuildCreate(with: data)
		case let (.guildDelete, .object(data)):	handleGuildDelete(with: data)
		case let (.guildUpdate, .object(data)):	handleGuildUpdate(with: data)
		case let (.guildEmojisUpdate, .object(data)):	handleGuildEmojiUpdate(with: data)
		case let (.channelUpdate, .object(data)):	handleChannelUpdate(with: data)
		case let (.channelCreate, .object(data)):	handleChannelCreate(with: data)
		case let (.channelDelete, .object(data)):	handleChannelDelete(with: data)
		case let (.voiceServerUpdate, .object(data)):	handleVoiceServerUpdate(with: data)
		case let (.voiceStateUpdate, .object(data)):	handleVoiceStateUpdate(with: data)
		case let (.ready, .object(data)):	handleReady(with: data)
		default:	handleEvent(event.rawValue, with: [data])
		}
	}
}
