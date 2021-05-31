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
import Logging
import Foundation

/// A enum representing a configuration option.
public enum DiscordClientOption : CustomStringConvertible, Equatable {
    /// If passed this option, the client will not store presences on the guild.
    case discardPresences

    /// This option causes the client to request all users for large guilds as soon as they are created.
    case fillLargeGuilds

    /// If a presence comes in on a large guild, and we don't have that user, setting this option
    /// will cause the client to query the API for that user.
    case fillUsers

    /// The dispatch queue that events should be handled on.
    /// This is also the queue that properties should be read from.
    case handleQueue(DispatchQueue)

    /// If this option is given, the client will automatically unload users who go offline. This can save some memory.
    /// However this means that invsible users will also be pruned.
    case pruneUsers

    /// The gateway intents. By default, only the unprivileged intents are used, i.e. you won't
    /// get guild member and presence events, unless you specify these here (e.g. by using .allIntents).
    case intents(DiscordGatewayIntent)

    /// A DiscordRateLimiter for this client. All REST calls will be put through this limiter.
    case rateLimiter(DiscordRateLimiterSpec)

    /// Tells the client the number of shards to create. If not provided, one shard will be created.
    case shardingInfo(DiscordShardInformation)

    /// The settings for voice engines. See `DiscordVoiceEngineConfiguration` for defaults.
    case voiceConfiguration(DiscordVoiceEngineConfiguration)

    // MARK: Properties

    /// - returns: A description of this option
    public var description: String {
        switch self {
        case .discardPresences:     return "discardPresences"
        case .fillLargeGuilds:      return "fillLargeGuilds"
        case .fillUsers:            return "fillUsers"
        case .handleQueue:          return "handleQueue"
        case .rateLimiter:          return "rateLimiter"
        case .shardingInfo:         return "shardingInfo"
        case .pruneUsers:           return "pruneUsers"
        case .intents:              return "intents"
        case .voiceConfiguration:   return "voiceConfiguration"
        }
    }

    /// Compares two DiscordClientOption's descriptions.
    /// - returns: true if they are the same
    public static func ==(lhs: DiscordClientOption, rhs: DiscordClientOption) -> Bool {
        return lhs.description == rhs.description
    }
}
