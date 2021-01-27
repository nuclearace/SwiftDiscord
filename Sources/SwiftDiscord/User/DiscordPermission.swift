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

/// Represents a Discord Permission. Calculating Permissions involves bitwise operations.
public struct DiscordPermission : OptionSet, Encodable {
    // TODO: Migrate to BigInt or similar since permission are string-serialized
    //       and may have arbitrary size as of v8

    public let rawValue: Int

    /// This user can create invites.
    public static let createInstantInvite = DiscordPermission(rawValue: 0x00000001)
    /// This user can kick members.
    public static let kickMembers = DiscordPermission(rawValue: 0x00000002)
    /// This user can ban members.
    public static let banMembers = DiscordPermission(rawValue: 0x00000004)
    /// This user is an admin.
    public static let administrator = DiscordPermission(rawValue: 0x00000008)
    /// This user can manage channels.
    public static let manageChannels = DiscordPermission(rawValue: 0x00000010)
    /// This user can manage the guild.
    public static let manageGuild = DiscordPermission(rawValue: 0x00000020)
    /// This user can add reactions.
    public static let addReactions = DiscordPermission(rawValue: 0x00000040)
    /// This user can view the audit log.
    public static let viewAuditLog = DiscordPermission(rawValue: 0x00000080)
    /// This user can read messages.
    public static let readMessages = DiscordPermission(rawValue: 0x00000400)
    /// This user can send messages.
    public static let sendMessages = DiscordPermission(rawValue: 0x00000800)
    /// This user can send tts messages.
    public static let sendTTSMessages = DiscordPermission(rawValue: 0x00001000)
    /// This user can manage messages.
    public static let manageMessages = DiscordPermission(rawValue: 0x00002000)
    /// This user can embed links.
    public static let embedLinks = DiscordPermission(rawValue: 0x00004000)
    /// This user can attach files.
    public static let attachFiles = DiscordPermission(rawValue: 0x00008000)
    /// This user read the message history.
    public static let readMessageHistory = DiscordPermission(rawValue: 0x00010000)
    /// This user can mention everyone.
    public static let mentionEveryone = DiscordPermission(rawValue: 0x00020000)
    /// This user can can add external emojis.
    public static let useExternalEmojis = DiscordPermission(rawValue: 0x00040000)
    /// This user can connect to a voice channel.
    public static let connect = DiscordPermission(rawValue: 0x00100000)
    /// This user can speak on a voice channel.
    public static let speak = DiscordPermission(rawValue: 0x00200000)
    /// This user can mute members.
    public static let muteMembers = DiscordPermission(rawValue: 0x00400000)
    /// This user can deafen members.
    public static let deafenMembers = DiscordPermission(rawValue: 0x00800000)
    /// This user can move members.
    public static let moveMembers = DiscordPermission(rawValue: 0x01000000)
    /// This user can use VAD.
    public static let useVAD = DiscordPermission(rawValue: 0x02000000)
    /// This user can change their nickname.
    public static let changeNickname = DiscordPermission(rawValue: 0x04000000)
    /// This user can manage nicknames.
    public static let manageNicknames = DiscordPermission(rawValue: 0x08000000)
    /// This user can manage roles.
    public static let manageRoles = DiscordPermission(rawValue: 0x10000000)
    /// This user can manage WebHooks
    public static let manageWebhooks = DiscordPermission(rawValue: 0x20000000)
    /// This user can manage emojis
    public static let manageEmojis = DiscordPermission(rawValue: 0x40000000)

    // MARK: Composite permissions

    /// All the channel permissions set to true.
    public static let allChannel = DiscordPermission(rawValue: 0x33F7FC51)

    /// All voice permissions set to true
    public static let voice = DiscordPermission(rawValue: 0x3F00000)

    /// User has all permissions.
    public static let all = DiscordPermission(rawValue: Int.max >> 10)

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue.description)
    }
}

/// Represents a permission overwrite type for a channel.
public enum DiscordPermissionOverwriteType : String, Encodable {
    /// A role overwrite.
    case role = "role"
    /// A member overwrite.
    case member = "member"
}

/// Represents a permission overwrite for a channel.
///
/// The `allow` and `deny` properties are bit fields.
public struct DiscordPermissionOverwrite : Encodable {
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

    init(permissionOverwriteObject: [String: Any]) {
        id = permissionOverwriteObject.getSnowflake()
        type = DiscordPermissionOverwriteType(rawValue: permissionOverwriteObject.get("type", or: "")) ?? .role
        allow = DiscordPermission(rawValue: Int(permissionOverwriteObject.get("allow", or: "0")) ?? 0)
        deny = DiscordPermission(rawValue: Int(permissionOverwriteObject.get("deny", or: "0")) ?? 0)
    }

    static func overwritesFromArray(_ permissionOverwritesArray: [[String: Any]]) -> [OverwriteID: DiscordPermissionOverwrite] {
        var overwrites = [OverwriteID: DiscordPermissionOverwrite]()

        for overwriteObject in permissionOverwritesArray {
            let overwrite = DiscordPermissionOverwrite(permissionOverwriteObject: overwriteObject)

            overwrites[overwrite.id] = overwrite
        }

        return overwrites
    }
}
