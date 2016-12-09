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
