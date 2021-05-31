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

/// Declares that a type will have a Discord token.
public protocol DiscordTokenBearer {
    // MARK: Properties

    /// The token for the user.
    var token: DiscordToken { get }
}

///
/// A type that represents a Discord JWT.
///
/// This type conforms to `ExpressibleByStringLiteral` so it can be created via string literals.
///
/// For example:
///
/// ```swift
/// let token = "Bot adfadf.adfdafdafdfa.afdaf" as DiscordToken
/// ```
///
/// The "Bot" prefix indicates that this token is a bot. This must included if the token is for a bot.
/// Likewise, if the token is an OAuth token, it must be preceded by "Bearer". User tokens can omit a prefix.
///
public struct DiscordToken : ExpressibleByStringLiteral, CustomStringConvertible {
    // MARK: Typealiases

    /// ExpressibleByStringLiteral conformance
    public typealias StringLiteralType = String

    /// ExpressibleByStringLiteral conformance.
    public typealias ExtendedGraphemeClusterLiteralType = String.ExtendedGraphemeClusterLiteralType

    /// ExpressibleByStringLiteral conformance.
    public typealias UnicodeScalarLiteralType = String.UnicodeScalarLiteralType

    // MARK: Properties

    /// The token string.
    public let token: String

    /// CustomStringConvertible conformance. Same as `token`.
    public var description: String {
        return token
    }

    /// Whether this token is a bot token.
    public var isBot: Bool {
        return token.hasPrefix("Bot")
    }

    /// Whether this token is an OAuth token.
    public var isBearer: Bool {
        return token.hasPrefix("Bearer")
    }

    /// Whether this token is a user token.
    public var isUser: Bool {
        return !(isBot || isBearer)
    }

    // MARK: Initializers

    ///
    /// ExpressibleByStringLiteral conformance.
    ///
    /// - parameter unicodeScalarLiteral: The unicode scalar literal
    ///
    public init(unicodeScalarLiteral value: UnicodeScalarLiteralType) {
        token = String(unicodeScalarLiteral: value)
    }

    ///
    /// ExpressibleByStringLiteral conformance.
    ///
    /// - parameter extendedGraphemeClusterLiteral: The grapheme scalar literal
    ///
    public init(extendedGraphemeClusterLiteral value: ExtendedGraphemeClusterLiteralType) {
        token = String(extendedGraphemeClusterLiteral: value)
    }

    ///
    /// ExpressibleByStringLiteral conformance.
    ///
    /// - parameter stringLiteral: The string literal
    ///
    public init(stringLiteral value: StringLiteralType) {
        token = value
    }
}
