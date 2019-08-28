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
import NIO
import AsyncWebSocketClient

/// Declares that a type will be an Engine for the Discord Gateway.
public protocol DiscordEngineSpec : DiscordShard {
    // MARK: Properties

    /// The last received sequence number. Used for resume/reconnect.
    var lastSequenceNumber: Int { get }

    /// The session id of this engine.
    var sessionId: String? { get set }
}

/// Declares that a type will be capable of communicating with Discord's WebSockets
public protocol DiscordWebSocketable : AnyObject {
    /// MARK: Properties

    /// The url to connect to.
    var connectURL: String { get }

    /// The UUID for this WebSocketable.
    var connectUUID: UUID { get set }

    /// A description of this WebSocketable.
    var description: String { get }

    /// The queue WebSockets do their parsing on.
    var parseQueue: DispatchQueue { get }

    /// A reference to the underlying WebSocket.
    var websocket: WebSocketClient.Socket? { get set }

    // MARK: Methods

    ///
    /// Attaches the WebSocket handlers that listen for text/connects/disconnects/etc
    ///
    /// Override if you need to provide custom handlers.
    ///
    func attachWebSocketHandlers()

    ///
    /// Starts the connection to the Discord gateway.
    ///
    func connect()

    ///
    /// Disconnects the engine. An `engine.disconnect` is fired on disconnection.
    ///
    func disconnect()

    ///
    /// Handles a close from the WebSocket.
    ///
    /// - parameter reason: The reason the socket closed.
    ///
    func handleClose(reason: Error?)
}

public extension DiscordWebSocketable where Self: DiscordGatewayable & DiscordRunLoopable {
    /// Default implementation.
    public func attachWebSocketHandlers() {
        websocket?.onText { [weak self] ws, text in
            guard let this = self else { return }

            DefaultDiscordLogger.Logger.debug("\(this.description), Got text: \(text)", type: "DiscordWebSocketable")

            this.parseGatewayMessage(text)
        }

        websocket?.onCloseCode { [weak self] code in
            guard let this = self else { return }

            DefaultDiscordLogger.Logger.log("WebSocket closed, code: \(code), \(this.description);",  type: "DiscordWebSocketable")

            this.handleClose(reason: nil)
        }
        
        websocket?.onError { [weak self] ws, err in
            guard let this = self else { return }
            
            DefaultDiscordLogger.Logger.log("WebSocket errored, \(err), \(this.description)", type: "DiscordWebSocketable")
        }
    }

    ///
    /// Starts the connection to the Discord gateway.
    ///
    public func connect() {
        runloop.execute(self._connect)
    }

    private func _connect() {
        DefaultDiscordLogger.Logger.log("Connecting to \(connectURL), \(description)", type: "DiscordWebSocketable")
        DefaultDiscordLogger.Logger.log("Attaching WebSocket, shard: \(description)", type: "DiscordWebSocketable")

        let url = URL(string: connectURL)!
        let path = url.path.isEmpty ? "/" : url.path
        let wsClient = WebSocketClient(eventLoopGroupProvider: .shared(runloop), configuration: .init(
            tlsConfiguration: .clientDefault,
            maxFrameSize: 1 << 31
        ))
        let future = wsClient.connect(
                host: url.host!,
                port: url.port ?? 443,
                uri: path
        ) { [weak self] ws in
            guard let this = self else { return }

            DefaultDiscordLogger.Logger.log("Websocket connected, shard: \(this.description)", type: "DiscordWebSocketable")

            this.websocket = ws
            this.connectUUID = UUID()

            this.attachWebSocketHandlers()
            this.startHandshake()
        }
        
        future.whenFailure { [weak self] err in
            guard let this = self else { return }
            
            DefaultDiscordLogger.Logger.log("Websocket errored, closing: \(err), \(this.description)", type: "DiscordWebSocketable")
            
            this.handleClose(reason: err)
        }
    }

    internal func closeWebSockets(fast: Bool = false) {
        DefaultDiscordLogger.Logger.log("Closing WebSocket, shard: \(description)", type: "DiscordWebSocketable")

        guard !fast else {
            handleClose(reason: nil)

            return
        }

        websocket?.close()
    }

    ///
    /// Logs that an error occured.
    ///
    /// - parameter message: The error message
    ///
    public func error(message: String) {
        DefaultDiscordLogger.Logger.error(message, type: description)
    }
}
