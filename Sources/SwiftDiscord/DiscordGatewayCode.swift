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

/// Top-level enum for gateway codes.
public enum DiscordGatewayCode {
	/// Gateway code is a DiscordNormalGatewayCode.
	case gateway(DiscordNormalGatewayCode)

	/// Gateway code is a DiscordVoiceGatewayCode.
	case voice(DiscordVoiceGatewayCode)

	var rawCode: Int {
		switch self {
		case let .gateway(gatewayCode):
			return gatewayCode.rawValue
		case let .voice(voiceCode):
			return voiceCode.rawValue
		}
	}
}

/// Represents a regular gateway code
public enum DiscordNormalGatewayCode : Int {
	/// Dispatch.
	case dispatch
	/// Heartbeat.
	case heartbeat
	/// Identify.
	case identify
	/// Status Update.
	case statusUpdate
	/// Voice Status Update.
	case voiceStatusUpdate
	/// Voice Server Ping.
	case voiceServerPing
	/// Resume.
	case resume
	/// Reconnect.
	case reconnect
	/// Request Guild Members.
	case requestGuildMembers
	/// Invalid Session.
	case invalidSession
	/// Hello.
	case hello
	/// HeartbeatAck
	case heartbeatAck
}

/// Represents a voice gateway code
public enum DiscordVoiceGatewayCode : Int {
	/// Identify.
	case identify
	/// Select Protocol.
	case selectProtocol
	/// Ready.
	case ready
	/// Heartbeat.
	case heartbeat
	/// Session Description.
	case sessionDescription
	/// Speaking.
	case speaking
}

/// Represents the reason a gateway was closed.
public enum DiscordGatewayCloseReason : Int {
	/// We don't quite know why the gateway closed.
	case unknown = 0

	/// The gateway closed because the network dropped.
	case noNetwork = 50

	/// The gateway closed from a normal WebSocket close event.
	case normal = 1000

	/// Something went wrong, but we aren't quite sure either.
	case unknownError = 4000

	/// Discord got an opcode is doesn't recognize.
	case unkownOpcode = 4001

	/// We sent a payload Discord doesn't know what to do with.
	case decodeError = 4002

	/// We tried to send stuff before we were authenticated.
	case notAuthenticated = 4003

	/// We failed to authenticate with Discord.
	case authenticationFailed = 4004

	/// We tried to authenticate twice.
	case alreadyAuthenticated = 4005

	/// We sent a bad sequence number when trying to resume.
	case invalidSequence = 4007

	/// We sent messages too fast.
	case rateLimited = 4008

	/// Our session timed out.
	case sessionTimeout = 4009

	/// We sent an invalid shard when identifing.
	case invalidShard = 4010

	// MARK: Initializers

	init?(error: NSError?) {
		guard let code = error?.code else { return nil }

		self.init(rawValue: code)
	}
}
