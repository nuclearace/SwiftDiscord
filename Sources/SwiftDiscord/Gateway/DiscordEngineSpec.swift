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
import Logging
import NIO
import WebSocketKit

fileprivate let logger = Logger(label: "DiscordEngineSpec")

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
    var websocket: WebSocket? { get set }

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
    func attachWebSocketHandlers() {
        websocket?.onText { [weak self] ws, text in
            guard let this = self else { return }

            logger.debug("\(this.description), Got text: \(text)")

            this.parseGatewayMessage(text)
        }
        
        websocket?.onClose.whenSuccess { [weak self] in
            guard let this = self else { return }
            
            logger.info("Websocket closed, \(this.description)")
            
            this.handleClose(reason: nil)
        }

        websocket?.onClose.whenFailure { [weak self] err in
            guard let this = self else { return }

            logger.info("WebSocket errored: \(err), \(this.description);")

            this.handleClose(reason: nil)
        }
    }

    ///
    /// Starts the connection to the Discord gateway.
    ///
    func connect() {
        runloop.execute(self._connect)
    }

    private func _connect() {
        logger.info("Connecting to \(connectURL), \(description)")
        logger.info("Attaching WebSocket, shard: \(description)")

        let url = URL(string: connectURL)!
        let path = url.path.isEmpty ? "/" : url.path

        let future = WebSocket.connect(
            scheme: url.scheme ?? "wss",
            host: url.host!,
            port: url.port ?? 443,
            path: path,
            configuration: .init(
                tlsConfiguration: .clientDefault,
                maxFrameSize: 1 << 31
            ),
            on: runloop
        ) { [weak self] ws in
            guard let this = self else { return }

            logger.info("Websocket connected, shard: \(this.description)")

            this.websocket = ws
            this.connectUUID = UUID()

            this.attachWebSocketHandlers()
            this.startHandshake()
        }
        
        future.whenFailure { [weak self] err in
            guard let this = self else { return }
            
            logger.info("Websocket errored, closing: \(err), \(this.description)")
            
            this.handleClose(reason: err)
        }
    }

    internal func closeWebSockets(fast: Bool = false) {
        logger.info("Closing WebSocket, shard: \(description)")

        guard !fast else {
            handleClose(reason: nil)

            return
        }

        let _ = websocket?.close()
    }

    ///
    /// Logs that an error occured.
    ///
    /// - parameter message: The error message
    ///
    func error(message: String) {
        logger.error("\(message)")
    }
}
