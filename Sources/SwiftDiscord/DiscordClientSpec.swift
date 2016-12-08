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

public protocol DiscordClientSpec : class, DiscordEngineClient, DiscordVoiceEngineClient {
	var connected: Bool { get }
	var guilds: [String: DiscordGuild] { get }
	var handleQueue: DispatchQueue { get set }
	var relationships: [[String: Any]] { get } // TODO make this a [DiscordRelationship]
	var token: DiscordToken { get }
	var user: DiscordUser? { get }
	var voiceState: DiscordVoiceState? { get }

	init(token: DiscordToken, configuration: [DiscordClientOption])

	func connect()
	func disconnect()
	func on(_ event: String, callback: @escaping ([Any]) -> Void)
	func handleEvent(_ event: String, with data: [Any])
	func joinVoiceChannel(_ channelId: String)
	func leaveVoiceChannel()
	func requestAllUsers(on guildId: String)
	func setPresence(_ presence: DiscordPresenceUpdate)
}
