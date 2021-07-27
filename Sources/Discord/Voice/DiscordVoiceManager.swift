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

import Dispatch
import Foundation
import Logging

fileprivate let logger = Logger(label: "DiscordVoiceManager")

/// A delegate for a VoiceManager.
public protocol DiscordVoiceManagerDelegate : AnyObject, DiscordTokenBearer, DiscordEventLoopGroupManager {
    // MARK: Methods

    ///
    /// Called when an engine disconnects.
    ///
    /// - parameter manager: The manager.
    /// - parameter engine: The engine that disconnected.
    ///
    func voiceManager(_ manager: DiscordVoiceManager, didDisconnectEngine engine: DiscordVoiceEngine)

    ///
    /// Called when a voice engine receives opus voice data.
    ///
    /// - parameter manager: The manager.
    /// - parameter didReceiveOpusVoiceData: The data received.
    /// - parameter fromEngine: The engine that received the data.
    ///
    func voiceManager(_ manager: DiscordVoiceManager, didReceiveOpusVoiceData data: DiscordOpusVoiceData,
                      fromEngine engine: DiscordVoiceEngine)

    ///
    /// Called when a voice engine receives raw voice data.
    ///
    /// - parameter manager: The manager.
    /// - parameter didReceiveRawVoiceData: The data received.
    /// - parameter fromEngine: The engine that received the data.
    ///
    func voiceManager(_ manager: DiscordVoiceManager, didReceiveRawVoiceData data: DiscordRawVoiceData,
                      fromEngine engine: DiscordVoiceEngine)

    ///
    /// Called when a voice engine is ready.
    ///
    /// - parameter manager: The manager.
    /// - parameter engine: The engine that's ready.
    ///
    func voiceManager(_ manager: DiscordVoiceManager, engineIsReady engine: DiscordVoiceEngine)

    ///
    /// Called when a voice engine needs a data source.
    ///
    /// - parameter manager: The manager that is requesting an encoder.
    /// - parameter engine: The engine that needs an encoder
    /// - returns: A data source.
    ///
    func voiceManager(_ manager: DiscordVoiceManager,
                      needsDataSourceForEngine engine: DiscordVoiceEngine) throws -> DiscordVoiceDataSource?
}

/// A manager for voice engines.
open class DiscordVoiceManager : DiscordVoiceEngineDelegate, Lockable {
    // MARK: Properties

    /// The delegate for this manager.
    public weak var delegate: DiscordVoiceManagerDelegate?

    /// The configuration for engines.
    public var engineConfiguration: DiscordVoiceEngineConfiguration

    /// The token for the user.
    public var token: DiscordToken {
        return delegate!.token
    }

    /// The voice engines, indexed by guild id.
    public private(set) var voiceEngines = DiscordIDDictionary<DiscordVoiceEngine>()

    /// The voice states for this user, if they are in any voice channels.
    public internal(set) var voiceStates = DiscordIDDictionary<DiscordVoiceState>()

    let lock = DispatchSemaphore(value: 1)

    var voiceServerInformations = DiscordIDDictionary<DiscordVoiceServerInformation>()

    private var logType: String { return "DiscordVoiceManager" }

    // MARK: Initializers

    ///
    /// Creates a new manager with the delegate set.
    ///
    public init(delegate: DiscordVoiceManagerDelegate,
                engineConfiguration: DiscordVoiceEngineConfiguration = DiscordVoiceEngineConfiguration()) {
        self.delegate = delegate
        self.engineConfiguration = engineConfiguration
    }

    // MARK: Methods

    ///
    /// Leaves the voice channel that is associated with the guild specified.
    ///
    /// - parameter onGuild: The snowflake of the guild that you want to leave.
    ///
    open func leaveVoiceChannel(onGuild guildId: GuildID) {
        guard let engine = get(voiceEngines[guildId]) else {
            logger.error("Could not find a voice engine for guild \(guildId)")

            return
        }

        protected {
            voiceStates[guildId] = nil
            voiceServerInformations[guildId] = nil
        }

        logger.debug("(verbose) Disconnecting voice engine for guild \(guildId)")

        engine.disconnect()

        // Make sure everything is cleaned out

        logger.debug("(verbose) Rejoining voice channels after leave")

        for (guildId, _) in voiceEngines {
            startVoiceConnection(guildId)
        }
    }

    ///
    /// Tries to open a voice connection to the specified guild.
    /// Only succeeds if we have both a voice state and the voice server info for this guild.
    ///
    /// - parameter guildId: The id of the guild to connect to.
    ///
    open func startVoiceConnection(_ guildId: GuildID) {
        protected {
            _startVoiceConnection(guildId)
        }
    }

    /// Tries to create a voice engine for a guild, and connect.
    /// **Not thread safe.**
    private func _startVoiceConnection(_ guildId: GuildID) {
        guard let delegate = delegate else { return }

        // We need both to start the connection
        guard let voiceState = voiceStates[guildId], let serverInfo = voiceServerInformations[guildId] else {
            return
        }

        // Reuse a previous engine's encoder if possible
        let previousEngine = voiceEngines[guildId]
        voiceEngines[guildId] = DiscordVoiceEngine(
                delegate: self,
                onLoop: delegate.runloops.next(),
                config: engineConfiguration,
                voiceServerInformation: serverInfo,
                voiceState: voiceState,
                source: previousEngine?.source,
                secret: previousEngine?.secret
        )

        logger.info("Connecting voice engine")

        DispatchQueue.global().async {[weak engine = voiceEngines[guildId]!] in
            engine?.connect()
        }
    }

    ///
    /// Called when the voice engine disconnects.
    ///
    /// - parameter engine: The engine that disconnected.
    ///
    open func voiceEngineDidDisconnect(_ engine: DiscordVoiceEngine) {
        delegate?.voiceManager(self, didDisconnectEngine: engine)

        protected { voiceEngines[engine.guildId] = nil }
    }

    ///
    /// Handles opus voice data received from a VoiceEngine
    ///
    /// - parameter didReceiveOpusVoiceData: A `DiscordOpusVoiceData` instance containing opus encoded voice data.
    ///
    open func voiceEngine(_ engine: DiscordVoiceEngine, didReceiveOpusVoiceData data: DiscordOpusVoiceData) {
        delegate?.voiceManager(self, didReceiveOpusVoiceData: data, fromEngine: engine)
    }

    ///
    /// Handles raw voice data received from a VoiceEngine
    ///
    /// - parameter didReceiveRawVoiceData: A `DiscordRawVoiceData` instance containing raw voice data.
    ///
    open func voiceEngine(_ engine: DiscordVoiceEngine, didReceiveRawVoiceData data: DiscordRawVoiceData) {
        delegate?.voiceManager(self, didReceiveRawVoiceData: data, fromEngine: engine)
    }

    ///
    /// Called when the voice engine needs an encoder.
    ///
    /// - parameter engine: The engine that needs an encoder
    /// - returns: An encoder.
    ///
    open func voiceEngineNeedsDataSource(_ engine: DiscordVoiceEngine) throws -> DiscordVoiceDataSource? {
        return try delegate?.voiceManager(self, needsDataSourceForEngine: engine)
    }

    ///
    /// Called when the voice engine is ready.
    ///
    /// - parameter engine: The engine that's ready.
    ///
    open func voiceEngineReady(_ engine: DiscordVoiceEngine) {
        delegate?.voiceManager(self, engineIsReady: engine)
    }


}
