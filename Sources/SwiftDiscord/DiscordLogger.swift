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

/// Represents the level of verbosity for the logger.
public enum DiscordLogLevel {
    /// Log nothing.
    case none
    /// Log connecting, disconnecting, events (but not content), etc.
    case info
    /// Log content of events.
    case verbose
    /// Log everything.
    case debug
}

/// Declares that a type will act as a logger.
public protocol DiscordLogger {
    // MARK: Properties

    /// Whether to log or not.
    var level: DiscordLogLevel { get set }

    // MARK: Methods

    /// Normal log messages.
    func log(_ message: String, type: String, args: Any...)

    /// More info on log messages.
    func verbose(_ message: String, type: String, args: Any...)

    /// Debug messages.
    func debug(_ message: String, type: String, args: Any...)

    /// Error Messages.
    func error(_ message: String, type: String, args: Any...)
}

public extension DiscordLogger {
    /// Normal log messages.
    func log(_ message: String, type: String, args: Any...) {
        guard level == .info || level == .verbose || level == .debug else { return }

        abstractLog("LOG", message: message, type: type, args: args)
    }

    /// More info on log messages.
    func verbose(_ message: String, type: String, args: Any...) {
        guard level == .verbose || level == .debug else { return }

        abstractLog("VERBOSE", message: message, type: type, args: args)
    }

    /// Debug messages.
    func debug(_ message: String, type: String, args: Any...) {
        guard level == .debug else { return }

        abstractLog("DEBUG", message: message, type: type, args: args)
    }

    /// Error Messages.
    func error(_ message: String, type: String, args: Any...) {
        abstractLog("ERROR", message: message, type: type, args: args)
    }

    private func abstractLog(_ logType: String, message: String, type: String, args: [Any]) {
        var message = "\(logType): \(type): \(message)"

        for arg in args {
            guard let range = message.range(of: "%@") else { break }

            message.replaceSubrange(range, with: String(describing: arg))
        }

        NSLog(message)
    }
}

class DefaultDiscordLogger : DiscordLogger {
    static var Logger: DiscordLogger = DefaultDiscordLogger()

    var level = DiscordLogLevel.none
}
