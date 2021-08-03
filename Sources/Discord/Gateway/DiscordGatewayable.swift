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
import Logging

fileprivate let logger = Logger(label: "DiscordGatewayable")

/// Declares that a type will communicate with a Discord gateway.
public protocol DiscordGatewayable: DiscordEngineHeartbeatable {
    // MARK: Methods

    ///
    /// Handles a DiscordGatewayEvent. You shouldn't need to call this directly.
    ///
    /// - parameter event: The payload object
    ///
    func handleGatewayPayload(_ event: DiscordGatewayEvent)

    ///
    /// Parses a raw message from the WebSocket. This is the entry point for all Discord events.
    /// You shouldn't call this directly.
    ///
    /// Override this method if you need to customize parsing.
    ///
    /// - parameter string: The raw payload string
    ///
    func parseAndHandleGatewayMessage(_ string: String)

    ///
    /// Sends a payload to Discord.
    ///
    /// - parameter payload: The payload to send.
    ///
    func sendPayload(_ payload: DiscordGatewayCommand)

    ///
    /// Starts the handshake with the Discord server. You shouldn't need to call this directly.
    ///
    /// Override this method if you need to customize the handshake process.
    ///
    func startHandshake()
}

public extension DiscordGatewayable where Self: DiscordWebSocketable & DiscordRunLoopable {
    /// Default Implementation.
    func sendPayload(_ payload: DiscordGatewayCommand) {
        guard let data = try? DiscordJSON.makeEncoder().encode(payload),
              let string = String(data: data, encoding: .utf8) else {
            logger.error("Could not create payload string for payload: \(payload)")

            return
        }

        logger.debug("Sending ws: \(string)")

        runloop.execute {
            self.websocket?.send(string)
        }
    }
}
