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

/// A enum representing a configuration option.
public enum DiscordClientOption : CustomStringConvertible, Equatable {
    /// The dispatch queue that events should be handled on.
    /// This is also the queue that properties should be read from.
    case handleQueue(DispatchQueue)

    /// The log level for the logger.
    case log(DiscordLogLevel)

    /// Used to set a custom logger.
    case logger(DiscordLogger)

    /// The number of shards this client should spawn. Defaults to 1.
    case shards(Int)

    // MARK: Properties

    /// - returns: A description of this option
    public var description: String {
        let description: String

        switch self {
        case .handleQueue:  description = "handleQueue"
        case .log:          description = "log"
        case .logger:       description = "logger"
        case .shards:       description = "shards"
        }

        return description
    }
}

/// Compares two DiscordClientOption's descriptions.
/// - returns: true if they are the same
public func ==(lhs: DiscordClientOption, rhs: DiscordClientOption) -> Bool {
    return lhs.description == rhs.description
}
