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

/// Represents the reason a gateway was closed.
public enum DiscordGatewayCloseReason: Int, Codable {
    /// We don't quite know why the gateway closed.
    case unknown = 0
    /// The gateway closed because the network dropped.
    case noNetwork = 50
    /// The gateway closed from a normal WebSocket close event.
    case normal = 1000
    /// Something went wrong, but we aren't quite sure either.
    case unknownError = 4000
    /// Discord got an opcode is doesn't recognize.
    case unknownOpcode = 4001
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
    /// We sent a protocol Discord doesn't recognize.
    case unknownProtocol = 4012
    /// We got disconnected.
    case disconnected = 4014
    /// The voice server crashed.
    case voiceServerCrash = 4015
    /// We sent an encryption mode Discord doesn't know.
    case unknownEncryptionMode = 4016

    // MARK: Initializers

    init?(error: Error?) {
        #if !os(Linux)
        guard let error = error else { return nil }

        self.init(rawValue: (error as NSError).opcode)
        #else
        self = .unknown
        #endif
    }
}
