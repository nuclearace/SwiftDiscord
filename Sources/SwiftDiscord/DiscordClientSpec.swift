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

import Foundation
import Dispatch

/// Protocol that abstracts a DiscordClient
public protocol DiscordClientSpec : class, DiscordEngineClient, DiscordVoiceEngineClient, DiscordUserActor {
	// MARK: Properties

	/// Whether or not this client is connected.
	var connected: Bool { get }

	/// The queue that callbacks are called on. In addition, any reads from any properties of DiscordClient should be
	/// made on this queue, as this is the queue where modifications on them are made.
	var handleQueue: DispatchQueue { get set }

	/// The current session id.
	var sessionId: String? { get }

	// MARK: Initializers

	/**
		- parameter token: The discord token of the user
		- parameter configuration: An array of DiscordClientOption that can be used to customize the client

	*/
	init(token: DiscordToken, configuration: [DiscordClientOption])

	// MARK: Methods

	/**
		Begins the connection to Discord. Once this is called, wait for a `connect` event before trying to interact
		with the client.
	*/
	func connect()

	/**
		Disconnects from Discord. A `disconnect` event is fired when the client has successfully disconnected.
	*/
	func disconnect()

	/**
		Adds event handlers to the client.

		- parameter event: The event to listen for
		- parameter callback: The callback that will be executed when this event is fired
	*/
	func on(_ event: String, callback: @escaping ([Any]) -> Void)

	/**
		The main event handle method. Calls the associated event handler.
		You shouldn't need to call this event directly.

		Override to provide custom event handling functionality.

		- parameter event: The event being fired
		- parameter with: The data from the event
	*/
	func handleEvent(_ event: String, with data: [Any])

	/**
		Joins a voice channel. A `voiceEngine.ready` event will be fired when the client has joined the channel.

		- parameter channelId: The snowflake of the voice channel you would like to join
	*/
	func joinVoiceChannel(_ channelId: String)

	/**
		Leaves the currently connected voice channel.
	*/
	func leaveVoiceChannel()

	/**
		Requests all users from Discord for the guild specified. Use this when you need to get all users on a large
		guild. Multiple `guildMembersChunk` will be fired.

		- parameter on: The snowflake of the guild you wish to request all users.
	*/
	func requestAllUsers(on guildId: String)

	/**
		Sets the user's presence.

		- parameter presence: The new presence object
	*/
	func setPresence(_ presence: DiscordPresenceUpdate)
}

/// Declares that a type will be able to reference a DiscordClient from within itself.
public protocol DiscordClientHolder {
	// MARK: Properties

	/// A reference to the client.
	weak var client: DiscordClient? { get set }
}
