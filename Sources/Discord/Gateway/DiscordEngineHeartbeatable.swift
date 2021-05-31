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

/// Declares that a type will send heartbeats to a Discord gateway.
public protocol DiscordEngineHeartbeatable {
    // MARK: Properties

    /// The number of milliseconds between heartbeats.
    var heartbeatInterval: Int { get }

    /// The `DispatchQueue` that the heartbeats are sent on.
    var heartbeatQueue: DispatchQueue { get }

    // MARK: Methods

    ///
    /// Starts sending heartbeats. After calling this heartbeating should be automatic.
    ///
    /// - parameter milliseconds: The number of milliseconds between heartbeats
    ///
    func startHeartbeat(milliseconds: Int)

    ///
    /// Sends a heartbeat to the gateway. This should be called from a timer/dispatch.after.
    ///
    func sendHeartbeat()
}
