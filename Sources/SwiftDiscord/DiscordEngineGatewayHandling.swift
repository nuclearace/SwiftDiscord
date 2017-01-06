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

/// Declares that a type will handle gateway dispatches.
public protocol DiscordEngineGatewayHandling : DiscordEngineSpec, DiscordEngineHeartbeatable {
    // MARK: Methods

    /**
        Handles a dispatch payload.

        - parameter payload: The dispatch payload
    */
	func handleDispatch(_ payload: DiscordGatewayPayload)

    /**
        Handles the hello event.

        - parameter payload: The dispatch payload
    */
    func handleHello(_ payload: DiscordGatewayPayload)

    /**
        Handles the resumed event.

        - parameter payload: The payload for the event.
    */
    func handleResumed(_ payload: DiscordGatewayPayload)
}

public extension DiscordEngineGatewayHandling {
    /// Default implementation
	func handleDispatch(_ payload: DiscordGatewayPayload) {
        guard let type = payload.name, let event = DiscordDispatchEvent(rawValue: type) else {
            DefaultDiscordLogger.Logger.error("Could not create dispatch event %@", type: "DiscordEngineGatewayHandling",
                args: payload)

            return
        }

        if event == .ready, case let .object(payloadObject) = payload.payload,
            let sessionId = payloadObject["session_id"] as? String {
                manager?.signalShardConnected(shardNum: shardNum)
                self.sessionId = sessionId
        } else if event == .resumed {
            handleResumed(payload)
        }

		client?.handleEngineDispatch(event, with: payload)
	}
}
