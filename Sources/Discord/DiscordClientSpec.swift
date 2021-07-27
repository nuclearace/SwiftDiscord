// The MIT License (MIT)
// Copyright (c) 2016 Erik Little
// Copyright (c) 2021 fwcd

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

import Foundation
import Dispatch

/// Protocol that abstracts a DiscordClient
public protocol DiscordClientSpec: DiscordVoiceManagerDelegate, DiscordShardManagerDelegate, DiscordUserActor {
	// MARK: Properties

	/// Whether or not this client is connected.
	var connected: Bool { get }

	/// The delegate for the client.
	var delegate: DiscordClientDelegate? { get set }

	/// The queue that callbacks are called on. In addition, any reads from any properties of DiscordClient should be
	/// made on this queue, as this is the queue where modifications on them are made.
	var handleQueue: DispatchQueue { get set }

	// MARK: Initializers

	///
	/// - parameter token: The discord token of the user.
	/// - parameter configuration: An array of DiscordClientOption that can be used to customize the client.
	/// - parameter delegate: The delegate for this client.
	///
	init(token: DiscordToken, delegate: DiscordClientDelegate, configuration: [DiscordClientOption])

	// MARK: Methods

	///
	/// Begins the connection to Discord. Once this is called, wait for a `connect` event before trying to interact
	/// with the client.
	///
	func connect()

	///
	/// Disconnects from Discord. A `disconnect` event is fired when the client has successfully disconnected.
	///
	func disconnect()

	///
	/// Joins a voice channel. A `voiceEngine.ready` event will be fired when the client has joined the channel.
	///
	/// - parameter channelId: The snowflake of the voice channel you would like to join
	///
	func joinVoiceChannel(_ channelId: ChannelID)

	///
	/// Leaves the currently connected voice channel.
	///
	/// - parameter onGuild: The snowflake of the guild whose voice channel you would like to leave.
	///
	func leaveVoiceChannel(onGuild guildId: GuildID)

	///
	/// Requests all users from Discord for the guild specified. Use this when you need to get all users on a large
	/// guild. Multiple `guildMembersChunk` will be fired.
	///
	/// - parameter on: The snowflake of the guild you wish to request all users.
	///
	func requestAllUsers(on guildId: GuildID)

	///
	/// Sets the user's presence.
	///
	/// - parameter presence: The new presence object
	///
	func setPresence(_ presence: DiscordPresenceUpdate)
}
