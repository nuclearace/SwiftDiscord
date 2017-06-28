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

/// The stored type of a Discord Snowflake ID
public struct Snowflake {


    /// The internal ID storage for a snowflake
    public let id: UInt64

    /// Initialize from a UInt64
    public init(_ snowflake: UInt64) {
        self.id = snowflake
    }

    /// Initialize from a string
    public init?(_ string: String) {
        guard let snowflake = UInt64(string) else { return nil }
        self.id = snowflake
    }

    /// Initialize from an optional string (returns nil if the input was nil or if it failed to initialize)
    init?(_ optionalString: String?) {
        guard let string = optionalString else { return nil }
        guard let snowflake = Snowflake(string) else { return nil }
        self = snowflake
    }
}

// MARK: Snowflake Typealiases
/// A Snowflake ID representing a Guild
public typealias GuildID = Snowflake

/// A Snowflake ID representing a Channel
public typealias ChannelID = Snowflake

/// A Snowflake ID representing a User
public typealias UserID = Snowflake

/// A Snowflake ID representing a Role
public typealias RoleID = Snowflake

/// A Snowflake ID representing a Message
public typealias MessageID = Snowflake

/// A Snowflake ID representing a Webhook
public typealias WebhookID = Snowflake

/// A Snowflake ID representing a Permissions Overwrite
public typealias OverwriteID = Snowflake

/// A Snowflake ID representing an Emoji
public typealias EmojiID = Snowflake

/// A Snowflake ID representing an Integration
public typealias IntegrationID = Snowflake

/// A Snowflake ID representing an Attachment
public typealias AttachmentID = Snowflake

// MARK: Snowflake Conformances

/// Snowflake conformance to JSONRepresentable
extension Snowflake : JSONRepresentable {
    func jsonValue() -> JSONRepresentable {
        // Snowflakes should be put into JSON as Strings
        return self.description
    }
}

/// Snowflake conformance to ExpressibleByIntegerLiteral
extension Snowflake : ExpressibleByIntegerLiteral {
    public typealias IntegerLiteralType = UInt64

    /// Initialize from an integer literal
    public init(integerLiteral value: UInt64) {
        self.id = value
    }
}

/// Snowflake conformance to CustomStringConvertible
extension Snowflake : CustomStringConvertible {

    /// Description for string Conversion
    public var description: String {
        return self.id.description
    }

}

/// Snowflake conformance to Comparable
extension Snowflake : Comparable {

    /// Used to check whether two Snowflakes are equal
    public static func ==(lhs: Snowflake, rhs: Snowflake) -> Bool {
        return lhs.id == rhs.id
    }

    /// Used to compare Snowflakes (which is useful because a greater Snowflake was made later)
    public static func <(lhs: Snowflake, rhs: Snowflake) -> Bool {
        return lhs.id < rhs.id
    }

}

/// Snowflake conformance to Hashable
extension Snowflake : Hashable {

    /// The hash value of the Snowflake
    public var hashValue: Int {
        return self.id.hashValue
    }

}
