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

/// Declares a type will be a delegate of a DiscordEngine.
public protocol DiscordEngineDelegate : class, DiscordTokenBearer {
    // MARK: Methods

    /**
        Handles engine dispatch events. You shouldn't need to call this method directly.

        Override to provide custom engine dispatch functionality.

        - parameter engine: The engine that received the event.
        - parameter didReceiveEvent: The event that was received.
        - parameter payload: A `DiscordGatewayPayload` containing the dispatch information.
    */
    func engine(_ engine: DiscordEngine, didReceiveEvent event: DiscordDispatchEvent,
                with payload: DiscordGatewayPayload)

    /**
        Called when an engine handled a hello packet.

        - parameter engine: The engine that received the event.
        - gotHelloWithPayload: The hello data.
    */
    func engine(_ engine: DiscordEngine, gotHelloWithPayload payload: DiscordGatewayPayload)
}
