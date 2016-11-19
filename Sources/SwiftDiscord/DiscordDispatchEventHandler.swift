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
	func handleMessageCreate(with data: [String: Any])
	func handlePresenceUpdate(with data: [String: Any])
	func handleReady(with data: [String: Any])
	func handleVoiceServerUpdate(with data: [String: Any])
	func handleVoiceStateUpdate(with data: [String: Any])
}

public extension DiscordDispatchEventHandler {
	func handleDispatch(event: DiscordDispatchEvent, data: DiscordGatewayPayloadData) {
		guard case let .object(eventData) = data else {
			DefaultDiscordLogger.Logger.error("Got dispatch event without an object: %@, %@",
				type: "DiscordDispatchEventHandler", args: event, data)

			return
		}

		switch event {
		case .presenceUpdate:		handlePresenceUpdate(with: eventData)
		case .messageCreate: 		handleMessageCreate(with: eventData)
		case .guildMemberAdd:		handleGuildMemberAdd(with: eventData)
		case .guildMembersChunk:	handleGuildMembersChunk(with: eventData)
		case .guildMemberUpdate:	handleGuildMemberUpdate(with: eventData)
		case .guildMemberRemove:	handleGuildMemberRemove(with: eventData)
		case .guildRoleCreate:		handleGuildRoleCreate(with: eventData)
		case .guildRoleDelete:		handleGuildRoleRemove(with: eventData)
		case .guildRoleUpdate:		handleGuildRoleUpdate(with: eventData)
		case .guildCreate:			handleGuildCreate(with: eventData)
		case .guildDelete:			handleGuildDelete(with: eventData)
		case .guildUpdate:			handleGuildUpdate(with: eventData)
		case .guildEmojisUpdate:	handleGuildEmojiUpdate(with: eventData)
		case .channelUpdate:		handleChannelUpdate(with: eventData)
		case .channelCreate:		handleChannelCreate(with: eventData)
		case .channelDelete:		handleChannelDelete(with: eventData)
		case .voiceServerUpdate:	handleVoiceServerUpdate(with: eventData)
		case .voiceStateUpdate:		handleVoiceStateUpdate(with: eventData)
		case .ready:				handleReady(with: eventData)
		default:					handleEvent(event.rawValue, with: [eventData])
		}
	}
}
