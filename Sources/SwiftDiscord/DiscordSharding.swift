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

/// Protocol that represents a sharded gateway connection.
public protocol DiscordShard {
    // MARK: Properties

    /// A reference to the manager
    weak var manager: DiscordShardManager? { get set }

    /// The total number of shards.
    var numShards: Int { get }

    /// This shard's number.
    var shardNum: Int { get }
}

/**
    The shard manager is responsible for a client's shards. It decides when a client is considered connected.
    Connected being when all shards have recieved a ready event and are receiving events from the gateway. It also
    decides when a client has fully disconnected. Disconnected being when all shards have closed.
*/
public class DiscordShardManager {
    // MARK: Properties

    /// - returns: The `n`th shard.
    public subscript(n: Int) -> DiscordEngineSpec {
        return shards[n]
    }

    /// The individual shards.
    public var shards = [DiscordEngineSpec]()

    private weak var client: DiscordClientSpec?
    private var closed = false
    private var closedShards = 0
    private var connectedShards = 0

    init(client: DiscordClientSpec) {
        self.client = client
    }

    // MARK: Methods

    /**
        Connects all shards to the gateway.

        **Note** This method is an async method.
    */
    public func connect() {
        closed = false

        DispatchQueue.global().async {[shards = self.shards] in
            for shard in shards {
                guard !self.closed else { break }

                shard.connect()

                Thread.sleep(forTimeInterval: 5.0)
            }
        }
    }

    /**
        Disconnects all shards.
    */
    public func disconnect() {
        closed = true

        for shard in shards {
            shard.disconnect()
        }
    }

    /**
        Creates the shards for this manager.

        - parameter into: The number of shards to create.
    */
    public func shatter(into numberOfShards: Int) {
        guard let client = self.client else { return }

        DefaultDiscordLogger.Logger.verbose("Shattering into %@ shards", type: "DiscordShardManager",
            args: numberOfShards)

        shards.removeAll()
        closedShards = 0
        connectedShards = 0

        for i in 0..<numberOfShards {
            let engine = DiscordEngine(client: client, shardNum: i, numShards: numberOfShards)

            engine.manager = self

            shards.append(engine)
        }
    }

    /**
        Used by shards to signal that they have connected.

        - parameter shardNum: The number of the shard that disconnected.
    */
    public func signalShardConnected(shardNum: Int) {
        connectedShards += 1

        guard connectedShards == shards.count else { return }

        client?.handleEvent("shardManager.connect", with: [])
    }

    /**
        Used by shards to signal that they have disconnected

        - parameter shardNum: The number of the shard that disconnected.
    */
    public func signalShardDisconnected(shardNum: Int) {
        closedShards += 1

        guard closedShards == shards.count else { return }

        client?.handleEvent("shardManager.disconnect", with: [])
    }
}
