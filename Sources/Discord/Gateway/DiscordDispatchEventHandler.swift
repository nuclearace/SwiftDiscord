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

/// Protocol that declares a type will handle Discord dispatch events.
public protocol DiscordDispatchEventHandler {
	// MARK: Methods

	///
	/// Handles channel creates from Discord.
	///
	/// - parameter with: The data from the event
	///
	func handleChannelCreate(with data: [String: Any])

	///
	/// Handles channel deletes from Discord.
	///
	/// - parameter with: The data from the event
	///
	func handleChannelDelete(with data: [String: Any])

	///
	/// Handles channel updates from Discord.
	///
	/// - parameter with: The data from the event
	///
	func handleChannelUpdate(with data: [String: Any])

	///
	/// Handles a dispatch event. This will call one of the other handle methods or the standard event handler.
	///
	/// - parameter event: The dispatch event
	/// - parameter data: The dispatch event's data
	///
	func handleDispatch(event: DiscordDispatchEvent, data: DiscordGatewayPayloadData)

	///
	/// Handles guild creates from Discord.
	///
	/// - parameter with: The data from the event
	///
	func handleGuildCreate(with data: [String: Any])

	///
	/// Handles guild deletes from Discord.
	///
	/// - parameter with: The data from the event
	///
	func handleGuildDelete(with data: [String: Any])

	///
	/// Handles guild emoji updates from Discord.
	///
	/// - parameter with: The data from the event
	///
	func handleGuildEmojiUpdate(with data: [String: Any])

	///
	/// Handles guild member adds from Discord.
	///
	/// - parameter with: The data from the event
	///
	func handleGuildMemberAdd(with data: [String: Any])

	///
	/// Handles guild member removes from Discord.
	///
	/// - parameter with: The data from the event
	///
	func handleGuildMemberRemove(with data: [String: Any])

	///
	/// Handles guild member updates from Discord.
	///
	/// - parameter with: The data from the event
	///
	func handleGuildMemberUpdate(with data: [String: Any])

	///
	/// Handles guild members chunks from Discord.
	///
	/// - parameter with: The data from the event
	///
	func handleGuildMembersChunk(with data: [String: Any])

	///
	/// Handles guild role creates from Discord.
	///
	/// - parameter with: The data from the event
	///
	func handleGuildRoleCreate(with data: [String: Any])

	///
	/// Handles guild role removes from Discord.
	///
	/// - parameter with: The data from the event
	///
	func handleGuildRoleRemove(with data: [String: Any])

	///
	/// Handles guild member updates from Discord.
	///
	/// - parameter with: The data from the event
	///
	func handleGuildRoleUpdate(with data: [String: Any])

	///
	/// Handles guild updates from Discord.
	///
	/// - parameter with: The data from the event
	///
	func handleGuildUpdate(with data: [String: Any])

	///
	/// Handles message creates from Discord.
	///
	/// 		- parameter with: The data from the event
	///
	func handleMessageCreate(with data: [String: Any])

	///
	/// Handles message updates from Discord.
	///
	/// - parameter with: The data from the event
	///
	func handleMessageUpdate(with data: [String: Any])

	///
	/// Handles presence updates from Discord.
	///
	/// - parameter with: The data from the event.
	///
	func handlePresenceUpdate(with data: [String: Any])

	///
	/// Handles the ready event from Discord.
	///
	/// - parameter with: The data from the event
	///
	func handleReady(with data: [String: Any])

	///
	/// Handles voice server updates from Discord.
	///
	/// - parameter with: The data from the event
	///
	func handleVoiceServerUpdate(with data: [String: Any])

	///
	/// Handles voice state updates from Discord.
	///
	/// - parameter with: The data from the event
	///
	func handleVoiceStateUpdate(with data: [String: Any])
}
