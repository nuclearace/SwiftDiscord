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

/// Represents a Discord Permission. Calculating Permissions involves bitwise operations.
public struct DiscordPermission: OptionSet, Codable {
    // TODO: Migrate to BigInt or similar since permission are string-serialized
    //       and may have arbitrary size as of v8

    public let rawValue: UInt64

    /// This user can create invites.
    public static let createInstantInvite = DiscordPermission(rawValue: 1 << 0)
    /// This user can kick members.
    public static let kickMembers = DiscordPermission(rawValue: 1 << 1)
    /// This user can ban members.
    public static let banMembers = DiscordPermission(rawValue: 1 << 2)
    /// This user is an admin.
    public static let administrator = DiscordPermission(rawValue: 1 << 3)
    /// This user can manage channels.
    public static let manageChannels = DiscordPermission(rawValue: 1 << 4)
    /// This user can manage the guild.
    public static let manageGuild = DiscordPermission(rawValue: 1 << 5)
    /// This user can add reactions.
    public static let addReactions = DiscordPermission(rawValue: 1 << 6)
    /// This user can view the audit log.
    public static let viewAuditLog = DiscordPermission(rawValue: 1 << 7)
    /// This user is a priority speaker in a voice channel.
    public static let prioritySpeaker = DiscordPermission(rawValue: 1 << 8)
    /// This user can go live.
    public static let stream = DiscordPermission(rawValue: 1 << 9)
    /// This user can view a channel in a guild, including reading messages.
    public static let viewChannel = DiscordPermission(rawValue: 1 << 10)
    /// This user can send messages.
    public static let sendMessages = DiscordPermission(rawValue: 1 << 11)
    /// This user can send tts messages.
    public static let sendTTSMessages = DiscordPermission(rawValue: 1 << 12)
    /// This user can manage messages.
    public static let manageMessages = DiscordPermission(rawValue: 1 << 13)
    /// This user can embed links.
    public static let embedLinks = DiscordPermission(rawValue: 1 << 14)
    /// This user can attach files.
    public static let attachFiles = DiscordPermission(rawValue: 1 << 15)
    /// This user read the message history.
    public static let readMessageHistory = DiscordPermission(rawValue: 1 << 16)
    /// This user can mention everyone.
    public static let mentionEveryone = DiscordPermission(rawValue: 1 << 17)
    /// This user can can add external emojis.
    public static let useExternalEmojis = DiscordPermission(rawValue: 1 << 18)
    /// This user can view guild insights.
    public static let viewGuildInsights = DiscordPermission(rawValue: 1 << 19)
    /// This user can connect to a voice channel.
    public static let connect = DiscordPermission(rawValue: 1 << 20)
    /// This user can speak on a voice channel.
    public static let speak = DiscordPermission(rawValue: 1 << 21)
    /// This user can mute members.
    public static let muteMembers = DiscordPermission(rawValue: 1 << 22)
    /// This user can deafen members.
    public static let deafenMembers = DiscordPermission(rawValue: 1 << 23)
    /// This user can move members.
    public static let moveMembers = DiscordPermission(rawValue: 1 << 24)
    /// This user can use VAD.
    public static let useVAD = DiscordPermission(rawValue: 1 << 25)
    /// This user can change their nickname.
    public static let changeNickname = DiscordPermission(rawValue: 1 << 26)
    /// This user can manage nicknames.
    public static let manageNicknames = DiscordPermission(rawValue: 1 << 27)
    /// This user can manage roles.
    public static let manageRoles = DiscordPermission(rawValue: 1 << 28)
    /// This user can manage WebHooks
    public static let manageWebhooks = DiscordPermission(rawValue: 1 << 29)
    /// This user can manage emojis and stickers
    public static let manageEmojisAndStickers = DiscordPermission(rawValue: 1 << 30)
    /// This user can use slash commands.
    public static let useSlashCommands = DiscordPermission(rawValue: 1 << 31)
    /// This user can request to speak in stage channels.
    public static let requestToSpeak = DiscordPermission(rawValue: 1 << 32)
    /// This user can delete and archive threads, also view all private threads.
    public static let manageThreads = DiscordPermission(rawValue: 1 << 34)
    /// This user can create and participate in threads.
    public static let usePublicThreads = DiscordPermission(rawValue: 1 << 35)
    /// This user can create and participate in private threads.
    public static let usePrivateThreads = DiscordPermission(rawValue: 1 << 36)
    /// This user can use custom stickers from other servers.
    public static let useExternalStickers = DiscordPermission(rawValue: 1 << 37)

    // MARK: Composite permissions

    /// All the channel permissions set to true.
    public static let allChannel = DiscordPermission(rawValue: 0x33F7FC51)

    /// All voice permissions set to true
    public static let voice = DiscordPermission(rawValue: 0x3F00000)

    /// User has all permissions.
    public static let all = DiscordPermission(rawValue: UInt64.max)

    public init(rawValue: UInt64) {
        self.rawValue = rawValue
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue.description)
    }
}

/// Represents a permission overwrite type for a channel.
public enum DiscordPermissionOverwriteType: String, Codable {
    /// A role overwrite.
    case role = "role"
    /// A member overwrite.
    case member = "member"
}

/// Represents a permission overwrite for a channel.
///
/// The `allow` and `deny` properties are bit fields.
public struct DiscordPermissionOverwrite: Codable, Identifiable {
    // MARK: Properties

    /// The snowflake id of this permission overwrite.
    public let id: OverwriteID

    /// The type of this overwrite.
    public let type: DiscordPermissionOverwriteType

    /// The permissions that this overwrite is allowed to use.
    public var allow: DiscordPermission

    /// The permissions that this overwrite is not allowed to use.
    public var deny: DiscordPermission

    // MARK: Initializers

    ///
    /// Creates a new DiscordPermissionOverwrite
    ///
    /// - parameter id: The id of this overwrite
    /// - parameter type: The type of this overwrite
    /// - parameter allow: The permissions allowed
    /// - parameter deny: The permissions denied
    ///
    public init(id: OverwriteID, type: DiscordPermissionOverwriteType, allow: DiscordPermission, deny: DiscordPermission) {
        self.id = id
        self.type = type
        self.allow = allow
        self.deny = deny
    }
}
