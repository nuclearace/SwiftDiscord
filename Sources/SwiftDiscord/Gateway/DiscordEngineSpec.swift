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

import Dispatch
import Foundation
#if !os(Linux)
import Starscream
#else
import WebSockets
#endif

/// Declares that a type will be an Engine for the Discord Gateway.
public protocol DiscordEngineSpec : class, DiscordShard {
    // MARK: Properties

    /// The last received sequence number. Used for resume/reconnect.
    var lastSequenceNumber: Int { get }

    /// The session id of this engine.
    var sessionId: String? { get set }
}

/// Declares that a type will be capable of communicating with Discord's WebSockets
public protocol DiscordWebSocketable : class {
    /// MARK: Properties

    /// The url to connect to.
    var connectURL: String { get }

    /// The UUID for this WebSocketable.
    var connectUUID: UUID { get set }

    /// A description of this WebSocketable.
    var description: String { get }

    /// The queue WebSockets do their parsing on.
    var parseQueue: DispatchQueue { get }

    /// A reference to the underlying WebSocket. This is a WebSockets.Websocket on Linux and Starscream.WebSocket on
    /// macOS/iOS.
    var websocket: WebSocket? { get set }

    // MARK: Methods

    /**
        Attaches the WebSocket handlers that listen for text/connects/disconnects/etc

        Override if you need to provide custom handlers.

        Note: You should handle both WebSockets.WebSocket and Starscream.WebSocket handlers.
    */
    func attachWebSocketHandlers()

    /**
        Starts the connection to the Discord gateway.
    */
    func connect()

    /**
        Disconnects the engine. An `engine.disconnect` is fired on disconnection.
    */
    func disconnect()

    /**
        Handles a close from the WebSocket.

        - parameter reason: The reason the socket closed.
    */
    func handleClose(reason: NSError?)
}

public extension DiscordWebSocketable where Self: DiscordGatewayable {
    /// Default implementation.
    public func attachWebSocketHandlers() {
        #if !os(Linux)
        websocket?.onConnect = {[weak self] in
            guard let this = self else { return }

            DefaultDiscordLogger.Logger.log("WebSocket Connected, \(this.description)", type: "DiscordWebSocketable")

            this.connectUUID = UUID()

            this.startHandshake()
        }

        websocket?.onDisconnect = {[weak self] err in
            guard let this = self else { return }

            DefaultDiscordLogger.Logger.log("WebSocket disconnected \(String(describing: err)), \(this.description)", type: "DiscordWebSocketable")

            this.handleClose(reason: err)
        }

        websocket?.onText = {[weak self] string in
            guard let this = self else { return }

            DefaultDiscordLogger.Logger.debug("\(this.description) Got text: \(string)", type: "DiscordWebSocketable")

            this.parseGatewayMessage(string)
        }
        #else
        websocket?.onText = {[weak self] ws, text in
            guard let this = self else { return }

            DefaultDiscordLogger.Logger.debug("\(this.description), Got text: \(text)", type: "DiscordWebSocketable")

            this.parseGatewayMessage(text)
        }

        websocket?.onClose = {[weak self] _, _, _, _ in
            guard let this = self else { return }

            DefaultDiscordLogger.Logger.log("WebSocket closed, \(this.description)", type: "DiscordWebSocketable")

            this.handleClose()
        }
        #endif
    }

    /**
        Starts the connection to the Discord gateway.
    */
    public func connect() {
        DefaultDiscordLogger.Logger.log("Connecting to \(connectURL), \(description)", type: "DiscordWebSocketable")
        DefaultDiscordLogger.Logger.log("Attaching WebSocket, shard: \(description)", type: "DiscordWebSocketable")

        #if !os(Linux)
        websocket = WebSocket(url: URL(string: connectURL)!)
        websocket?.callbackQueue = parseQueue

        attachWebSocketHandlers()
        websocket?.connect()
        #else
        try? WebSocket.background(to: connectURL) {[weak self] ws in
            guard let this = self else { return }
            DefaultDiscordLogger.Logger.log("Websocket connected, shard: \(this.description)", type: "DiscordWebSocketable")

            this.websocket = ws
            this.connectUUID = UUID()

            this.attachWebSocketHandlers()
            this.startHandshake()
        }
        #endif
    }

    internal func closeWebSockets() {
        #if !os(Linux)
        websocket?.disconnect()
        #else
        try? websocket?.close()
        #endif
    }

    /**
        Logs that an error occured.

        - parameter message: The error message
    */
    public func error(message: String) {
        DefaultDiscordLogger.Logger.error(message, type: description)
    }
}
