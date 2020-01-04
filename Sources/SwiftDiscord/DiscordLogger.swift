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

import Foundation
import Logging

/// Represents the level of verbosity for the logger.
public enum DiscordLogLevel {
    /// Log nothing.
    case none
    /// Log connecting, disconnecting, events (but not content), etc.
    case info
    /// Log content of events.
    case verbose
    /// Log almost everything, minus the noisiest things.
    case debug
    /// Log everything.
    case trace
}

/// Declares that a type will act as a logger.
public protocol DiscordLogger {
    // MARK: Properties

    /// Whether to log or not.
    var level: DiscordLogLevel { get set }

    // MARK: Methods

    /// Error Messages.
    func error(_ message: @autoclosure () -> String, type: String)

    /// Normal log messages.
    func log( _ message: @autoclosure () -> String, type: String)

    /// More info on log messages.
    func verbose(_ message: @autoclosure () -> String, type: String)

    /// Debug messages.
    func debug(_ message: @autoclosure () -> String, type: String)

    /// Trace Messages.
    func trace(_ message: @autoclosure () -> String, type: String)
}

class DefaultDiscordLogger : DiscordLogger {
    static var logger: DiscordLogger = DefaultDiscordLogger()
    
    private var downstreamLogger = Logger(label: "SwiftDiscord")
    var level = DiscordLogLevel.none
    
    /// Error Messages.
    func error(_ message: @autoclosure () -> String, type: String) {
        abstractLog(.error, message: message(), type: type)
    }

    /// Normal log messages.
    func log(_ message: @autoclosure () -> String, type: String) {
        abstractLog(.info, message: message(), type: type)
    }

    /// More info on log messages.
    func verbose(_ message: @autoclosure () -> String, type: String) {
        abstractLog(.debug, message: message(), type: type)
    }

    /// Debug messages.
    func debug(_ message: @autoclosure () -> String, type: String) {
        abstractLog(.debug, message: message(), type: type)
    }

    /// Trace Messages.
    func trace(_ message: @autoclosure () -> String, type: String) {
        abstractLog(.trace, message: message(), type: type)
    }

    private func abstractLog(_ level: Logger.Level, message: String, type: String) {
        downstreamLogger.log(level: level, "\(type): \(message)")
    }
}
