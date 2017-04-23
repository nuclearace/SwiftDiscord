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

/// A delegate for a VoiceManager.
public protocol DiscordVoiceManagerDelegate : class, DiscordTokenBearer {
    // MARK: Methods

    /**
        Called when an engine disconnects.

        - parameter manager: The manager.
        - parameter engine: The engine that disconnected.
    */
    func voiceManager(_ manager: DiscordVoiceManager, didDisconnectEngine engine: DiscordVoiceEngine)

    /**
        Called when a voice engine receives voice data.

        - parameter manager: The manager.
        - parameter didReceiveVoiceData: The data received.
        - parameter fromEngine: The engine that received the data.
    */
    func voiceManager(_ manager: DiscordVoiceManager, didReceiveVoiceData data: DiscordVoiceData,
                      fromEngine engine: DiscordVoiceEngine)

    /**
        Called when a voice engine is ready.

        - parameter manager: The manager.
        - parameter engine: The engine that's ready.
    */
    func voiceManager(_ manager: DiscordVoiceManager, engineIsReady engine: DiscordVoiceEngine)

    /**
        Called when a voice engine needs an encoder.

        - parameter manager: The manager that is requesting an encoder.
        - parameter engine: The engine that needs an encoder
        - returns: An encoder.
    */
    func voiceManager(_ manager: DiscordVoiceManager,
                      needsEncoderForEngine engine: DiscordVoiceEngine) throws -> DiscordVoiceEncoder?
}

/// A manager for voice engines.
open class DiscordVoiceManager : DiscordVoiceEngineDelegate, Lockable {
    // MARK: Properties

    /// The delegate for this manager.
    public weak var delegate: DiscordVoiceManagerDelegate?

    /// The token for the user.
    public var token: DiscordToken {
        return delegate!.token
    }

    /// The voice engines, indexed by guild id.
    public private(set) var voiceEngines = [String: DiscordVoiceEngine]()

    /// The voice states for this user, if they are in any voice channels.
    public internal(set) var voiceStates = [String: DiscordVoiceState]()

    let lock = DispatchSemaphore(value: 1)

    var voiceServerInformations = [String: DiscordVoiceServerInformation]()

    private let logType = "DiscordVoiceManager"

    // MARK: Initializers

    /**
        Creates a new manager with the delegate set.
    */
    public init(delegate: DiscordVoiceManagerDelegate) {
        self.delegate = delegate
    }

    // MARK: Methods

    /**
        Leaves the voice channel that is associated with the guild specified.

        - parameter onGuild: The snowflake of the guild that you want to leave.
    */
    open func leaveVoiceChannel(onGuild guildId: String) {
        guard let engine = get(voiceEngines[guildId]) else { return }

        protected {
            voiceStates[guildId] = nil
            voiceServerInformations[guildId] = nil
        }

        engine.disconnect()

        // Make sure everything is cleaned out

        for (guildId, _) in voiceEngines {
            startVoiceConnection(guildId)
        }
    }

    /**
        Tries to open a voice connection to the specified guild.
        Only succeeds if we have both a voice state and the voice server info for this guild.

        - parameter guildId: The id of the guild to connect to.
    */
    open func startVoiceConnection(_ guildId: String) {
        protected {
            _startVoiceConnection(guildId)
        }
    }

    /// Tries to create a voice engine for a guild, and connect.
    /// **Not thread safe.**
    private func _startVoiceConnection(_ guildId: String) {
        // We need both to start the connection
        guard let voiceState = voiceStates[guildId], let serverInfo = voiceServerInformations[guildId] else {
            return
        }

        // Reuse a previous engine's encoder if possible
        let previousEngine = voiceEngines[guildId]
        voiceEngines[guildId] = DiscordVoiceEngine(delegate: self,
                                                   voiceServerInformation: serverInfo,
                                                   voiceState: voiceState,
                                                   encoder: previousEngine?.encoder,
                                                   secret: previousEngine?.secret)

        DefaultDiscordLogger.Logger.log("Connecting voice engine", type: logType)

        voiceEngines[guildId]?.connect()
    }

    /**
        Called when the voice engine disconnects.

        - parameter engine: The engine that disconnected.
    */
    open func voiceEngineDidDisconnect(_ engine: DiscordVoiceEngine) {
        delegate?.voiceManager(self, didDisconnectEngine: engine)

        protected { voiceEngines[engine.guildId] = nil }
    }

    /**
        Handles voice data received from a VoiceEngine

        - parameter didReceiveVoiceData: A DiscordVoiceData tuple
    */
    open func voiceEngine(_ engine: DiscordVoiceEngine, didReceiveVoiceData data: DiscordVoiceData) {
        delegate?.voiceManager(self, didReceiveVoiceData: data, fromEngine: engine)
    }

    /**
        Called when the voice engine needs an encoder.

        - parameter engine: The engine that needs an encoder
        - returns: An encoder.
    */
    open func voiceEngineNeedsEncoder(_ engine: DiscordVoiceEngine) throws -> DiscordVoiceEncoder? {
        return try delegate?.voiceManager(self, needsEncoderForEngine: engine)
    }

    /**
        Called when the voice engine is ready.

        - parameter engine: The engine that's ready.
    */
    open func voiceEngineReady(_ engine: DiscordVoiceEngine) {
        delegate?.voiceManager(self, engineIsReady: engine)
    }


}
