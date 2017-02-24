// The MIT License (MIT)
// Copyright (c) 2017 Erik Little

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

/// Declares that a type will be a client for a voice engine.
public protocol DiscordVoiceEngineDelegate : DiscordEngineDelegate {
    // MARK: Methods

    /**
        Handles received voice data from a voice engine.

        - parameter data: The voice data that was received
    */
    func voiceEngine(_ engine: DiscordVoiceEngine, didReceiveVoiceData data: DiscordVoiceData)

    /**
        Called when the voice engine disconnects.

        - parameter engine: The engine that disconnected.
    */
    func voiceEngineDidDisconnect(_ engine: DiscordVoiceEngine)

    /**
        Called when the voice engine needs an encoder.

        - parameter engine: The engine that needs an encoder.
        - returns: An encoder.
    */
    func voiceEngineNeedsEncoder(_ engine: DiscordVoiceEngine) throws -> DiscordVoiceEncoder?

    /**
        Called when the voice engine is ready.

        - parameter engine: The engine that's ready.
    */
    func voiceEngineReady(_ engine: DiscordVoiceEngine)
}
