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

fileprivate let logger = Logger(label: "DiscordSharding")

/// Struct that represents shard information.
/// Used when a client is doing manual sharding.
public struct DiscordShardInformation {
    /// Sharding errors.
    public enum ShardingError : Error {
        /// Thrown when a shardRange's end is greater than or equal to the total number of shards.
        /// A range should always be `n..<m` where m is <= the total number of shards.
        case invalidShardRange
    }

    // MARK: Properties

    /// The range of shards in this client.
    public let shardRange: CountableRange<Int>

    /// The total number of shards this bot will have.
    public let totalShards: Int

    // MARK: Initializers

    ///
    /// Creates a new DiscordShardInformation telling the client the range of shards that it should spawn.
    ///
    public init(shardRange: CountableRange<Int>, totalShards: Int) throws {
        guard shardRange.first! >= 0 && shardRange.last! < totalShards else { throw ShardingError.invalidShardRange }

        self.shardRange = shardRange
        self.totalShards = totalShards
    }
}

/// Marks that a type will contain a runloop.
public protocol DiscordRunLoopable {
    /// The run loop for this entity.
    var runloop: EventLoop { get }
}

/// Declares that a type will be manager of a run loop.
public protocol DiscordEventLoopGroupManager {
    // MARK: Properties

    /// The run loops.
    var runloops: MultiThreadedEventLoopGroup { get }
}

/// Protocol that represents a sharded gateway connection. This is the top-level protocol for `DiscordEngineSpec` and
/// `DiscordEngine`
public protocol DiscordShard : DiscordWebSocketable, DiscordGatewayable, DiscordRunLoopable {
    // MARK: Properties

    /// Whether this shard is connected to the gateway
    var connected: Bool { get }

    /// A reference to the client this engine is associated with.
    var delegate: DiscordShardDelegate? { get }

    /// The total number of shards.
    var numShards: Int { get }

    /// This shard's number.
    var shardNum: Int { get }

    // MARK: Initializers

    ///
    /// The main initializer.
    ///
    /// - parameter client: The client this engine should be associated with.
    ///
    init(delegate: DiscordShardDelegate, shardNum: Int, numShards: Int, intents: DiscordGatewayIntent, onLoop: EventLoop)
}

/// Declares that a type will be a shard's delegate.
public protocol DiscordShardDelegate : AnyObject, DiscordTokenBearer {
    ///
    /// Used by shards to signal that they have connected.
    ///
    /// - parameter shardNum: The number of the shard that disconnected.
    ///
    func shardDidConnect(_ shard: DiscordShard)

    ///
    /// Used by shards to signal that they have disconnected
    ///
    /// - parameter shardNum: The number of the shard that disconnected.
    ///
    func shardDidDisconnect(_ shard: DiscordShard)

    ///
    /// Handles engine dispatch events. You shouldn't need to call this method directly.
    ///
    /// Override to provide custom engine dispatch functionality.
    ///
    /// - parameter engine: The engine that received the event.
    /// - parameter didReceiveEvent: The event that was received.
    /// - parameter payload: A `DiscordGatewayPayload` containing the dispatch information.
    ///
    func shard(_ engine: DiscordShard, didReceiveEvent event: DiscordDispatchEvent,
               with payload: DiscordGatewayPayload)

    ///
    /// Called when an engine handled a hello packet.
    ///
    /// - parameter engine: The engine that received the event.
    /// - gotHelloWithPayload: The hello data.
    ///
    func shard(_ engine: DiscordShard, gotHelloWithPayload payload: DiscordGatewayPayload)
}

/// The delegate for a `DiscordShardManager`.
public protocol DiscordShardManagerDelegate : AnyObject, DiscordEventLoopGroupManager, DiscordTokenBearer {
    // MARK: Methods

    ///
    /// Signals that the manager has finished connecting.
    ///
    /// - parameter manager: The manager.
    /// - parameter didConnect: Should always be true.
    ///
    func shardManager(_ manager: DiscordShardManager, didConnect connected: Bool)

    ///
    /// Signals that the manager has disconnected.
    ///
    /// - parameter manager: The manager.
    /// - parameter didDisconnectWithReason: The reason the manager disconnected.
    ///
    func shardManager(_ manager: DiscordShardManager, didDisconnectWithReason reason: String)

    ///
    /// Signals that the manager received an event. The client should handle this.
    ///
    /// - parameter manager: The manager.
    /// - parameter shouldHandleEvent: The event to be handled.
    /// - parameter withPayload: The payload that came with the event.
    ///
    func shardManager(_ manager: DiscordShardManager, shouldHandleEvent event: DiscordDispatchEvent,
                      withPayload payload: DiscordGatewayPayload)
}

///
/// The shard manager is responsible for a client's shards. It decides when a client is considered connected.
/// Connected being when all shards have recieved a ready event and are receiving events from the gateway. It also
/// decides when a client has fully disconnected. Disconnected being when all shards have closed.
///
open class DiscordShardManager : DiscordShardDelegate, Lockable {
    // MARK: Properties

    /// - returns: The shard with num `n`
    public subscript(n: Int) -> DiscordShard {
        return get(shards).first(where: { $0.shardNum == n })!
    }

    /// The token for the user.
    public var token: DiscordToken {
        return delegate!.token
    }

    /// The individual shards.
    public var shards = [DiscordShard]()

    let lock = DispatchSemaphore(value: 1)

    private var closed = false
    private var closedShards = 0
    private var connectedShards = 0
    private weak var delegate: DiscordShardManagerDelegate?

    init(delegate: DiscordShardManagerDelegate) {
        self.delegate = delegate
    }

    // MARK: Methods

    private func cleanUp() {
        protected {
            shards.removeAll()
            closedShards = 0
            connectedShards = 0
        }
    }

    ///
    /// Connects all shards to the gateway.
    ///
    /// **Note** This method is an async method.
    ///
    open func connect() {
        protected { closed = false }
        let shards = get(self.shards)

        for (i, shard) in shards.enumerated() {
            let deadline = DispatchTime.now() +  Double(5 * i)
            DispatchQueue.global().asyncAfter(deadline: deadline) { [weak self, weak shard] in
                guard let this = self, this.get(!this.closed) else { return }
                shard?.connect()
            }
        }
    }

    ///
    /// Creates a new shard.
    ///
    /// - parameter delegate: The delegate for this shard.
    /// - parameter withShardNum: The shard number for the new shard.
    /// - parameter totalShards: The total number of shards.
    /// - returns: A new `DiscordShard`
    ///
    open func createShardWithDelegate(_ delegate: DiscordShardManagerDelegate, withShardNum shardNum: Int,
                                      totalShards: Int, intents: DiscordGatewayIntent, onloop: EventLoop) -> DiscordShard {
        return DiscordEngine(delegate: self, shardNum: shardNum, numShards: totalShards, intents: intents, onLoop: onloop)
    }

    ///
    /// Disconnects all shards.
    ///
    open func disconnect() {
        protected {
            closed = true

            for shard in shards {
                shard.disconnect()
            }
        }

        if get(connectedShards != shards.count) {
            // Still connecting, say we disconnected, since we never connected to begin with
            delegate?.shardManager(self, didDisconnectWithReason: "Closed")
        }
    }

    ///
    /// Use when you will have multiple shards spread across a few instances.
    ///
    /// - parameter withInfo: The information about this single shard.
    ///
    open func manuallyShatter(withInfo info: DiscordShardInformation, intents: DiscordGatewayIntent) {
        guard let delegate = self.delegate else { return }

        logger.debug("(verbose) Handling shard range \(info.shardRange)")

        cleanUp()

        protected {
            for shardNum in info.shardRange {
                shards.append(createShardWithDelegate(delegate,
                                                      withShardNum: shardNum,
                                                      totalShards: info.totalShards,
                                                      intents: intents,
                                                      onloop: delegate.runloops.next()))
            }
        }
    }

    ///
    /// Sends a payload on the specified shard.
    ///
    /// - parameter payload: The payload to send.
    /// - parameter onShard: The shard to send the payload on.
    ///
    open func sendPayload(_ payload: DiscordGatewayPayload, onShard shard: Int) {
        self[shard].sendPayload(payload)
    }

    ///
    /// Handles engine dispatch events. You shouldn't need to call this method directly.
    ///
    /// Override to provide custom engine dispatch functionality.
    ///
    /// - parameter shard: The engine that received the event.
    /// - parameter didReceiveEvent: The event that was received.
    /// - parameter payload: A `DiscordGatewayPayload` containing the dispatch information.
    ///
    open func shard(_ shard: DiscordShard, didReceiveEvent event: DiscordDispatchEvent,
                    with payload: DiscordGatewayPayload) {
        delegate?.shardManager(self, shouldHandleEvent: event, withPayload: payload)
    }

    ///
    /// Called when an engine handled a hello packet.
    ///
    /// - parameter shard: The shard that received the event.
    /// - gotHelloWithPayload: The hello data.
    ///
    open func shard(_ engine: DiscordShard, gotHelloWithPayload payload: DiscordGatewayPayload) { }

    ///
    /// Used by shards to signal that they have connected.
    ///
    /// - parameter shardNum: The number of the shard that disconnected.
    ///
    open func shardDidConnect(_ shard: DiscordShard) {
        logger.debug("(verbose) Shard #\(shard.shardNum), connected")

        protected { connectedShards += 1 }

        guard get(connectedShards == shards.count) else { return }

        delegate?.shardManager(self, didConnect: true)
    }

    ///
    /// Used by shards to signal that they have disconnected
    ///
    /// - parameter shardNum: The number of the shard that disconnected.
    ///
    open func shardDidDisconnect(_ shard: DiscordShard) {
        logger.debug("(verbose) Shard #\(shard.shardNum), disconnected")

        protected { closedShards += 1 }

        guard get(closedShards == shards.count) else { return }

        delegate?.shardManager(self, didDisconnectWithReason: "Closed")
    }
}
