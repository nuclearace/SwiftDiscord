// The MIT License (MIT)
// Copyright (c) 2016 Erik Little
// Copyright (c) 2021 fwcd

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

/// Represents a Discord user.
public struct DiscordUser: Codable, Identifiable, Hashable {
    public enum CodingKeys: String, CodingKey {
        case avatar
        case bot
        case discriminator
        case email
        case id
        case mfaEnabled = "mfa_enabled"
        case username
        case verified
    }

    // MARK: Properties

    /// The snowflake id of the user.
    public var id: UserID

    /// The base64 encoded avatar of this user.
    public var avatar: String? = nil

    /// Whether this user is a bot.
    public var bot: Bool? = nil

    /// This user's discriminator.
    public var discriminator: String? = nil

    /// The user's email. Only availabe if we are the user.
    public var email: String? = nil

    /// Whether this user has multi-factor authentication enabled.
    public var mfaEnabled: Bool? = nil

    /// This user's username.
    public var username: String? = nil

    /// Whether this user is verified.
    public var verified: Bool? = nil
}
