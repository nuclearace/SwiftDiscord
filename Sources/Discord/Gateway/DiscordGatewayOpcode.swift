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

/// Represents a regular gateway opcode
public enum DiscordNormalGatewayOpcode: Int, Codable {
    /// Dispatch.
    case dispatch = 0
    /// Heartbeat.
    case heartbeat = 1
    /// Identify.
    case identify = 2
    /// Status Update.
    case statusUpdate = 3
    /// Voice Status Update.
    case voiceStatusUpdate = 4
    /// Voice Server Ping.
    case voiceServerPing = 5
    /// Resume.
    case resume = 6
    /// Reconnect.
    case reconnect = 7
    /// Request Guild Members.
    case requestGuildMembers = 8
    /// Invalid Session.
    case invalidSession = 9
    /// Hello.
    case hello = 10
    /// HeartbeatAck
    case heartbeatAck = 11
}
