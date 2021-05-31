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

import Logging

fileprivate let logger = Logger(label: "DiscordGuildChannel")

/// Protocol that declares a type will be a Discord guild channel.
public protocol DiscordGuildChannel : DiscordChannel {
    /// The snowflake id of the guild this channel is on.
    var guildId: GuildID { get }

    /// The name of this channel.
    var name: String { get }

    /// The parent category for this channel.
    var parentId: ChannelID? { get }

    /// The position of this channel. Mostly for UI purpose.
    var position: Int { get }

    /// The permissions specific to this channel.
    var permissionOverwrites: [OverwriteID: DiscordPermissionOverwrite] { get }
}

extension DiscordGuildChannel {
    // MARK: GuildChannel Methods

    ///
    /// Determines whether this user has the specified permission on this channel.
    ///
    /// - parameter member: The member to check.
    /// - parameter permission: The permission to check for.
    /// - returns: Whether the user has this permission in this channel.
    ///
    public func canMember(_ member: DiscordGuildMember, _ permission: DiscordPermission) -> Bool {
        return permissions(for: member).contains(permission)
    }

    ///
    /// Deletes a permission overwrite from this channel.
    ///
    /// - parameter overwrite: The permission overwrite to delete
    ///
    public func deletePermission(_ overwrite: DiscordPermissionOverwrite) {
        guard let client = self.client else { return }

        client.deleteChannelPermission(overwrite.id, on: id)
    }

    ///
    /// Edits a permission overwrite on this channel.
    ///
    /// - parameter overwrite: The permission overwrite to edit
    ///
    public func editPermission(_ overwrite: DiscordPermissionOverwrite) {
        guard let client = self.client else { return }

        client.editChannelPermission(overwrite, on: id)
    }

    ///
    /// Gets the permission overwrites for a user.
    ///
    /// - parameter for: The member to get permission overwrites for.
    /// - returns: The permission overwrites this member has.
    ///
    public func overwrites(for member: DiscordGuildMember) -> [DiscordPermissionOverwrite] {
        return permissionOverwrites.filter({ member.roleIds.contains($0.key) || member.user.id == $0.key }).map({ $0.1 })
    }

    ///
    /// Gets the permissions for this member on this channel.
    ///
    /// Takes into consideration whether they are the owner, admin, and any roles and permission overwrites they have.
    ///
    /// - parameter member: The member to check.
    /// - returns: The permissions that this user has, OR'd together.
    ///
    public func permissions(for member: DiscordGuildMember) -> DiscordPermission {
        guard let guild = self.guild else { return [] }
        guard guild.ownerId != member.user.id else { return DiscordPermission.all } // Owner has all permissions

        var workingPermissions = guild.roles(for: member).reduce([] as DiscordPermission, { $0.union($1.permissions) })
        if let everybodyRole = guild.roles[guild.id] {
            workingPermissions.formUnion(everybodyRole.permissions)
        }

        if workingPermissions.contains(.administrator) {
            // Admin has all permissions
            return DiscordPermission.all
        }

        if let everybodyOverwrite = self.permissionOverwrites[guild.id] {
            workingPermissions.subtract(everybodyOverwrite.deny)
            workingPermissions.formUnion(everybodyOverwrite.allow)
        }

        let roleOverwrites = permissionOverwrites.values.lazy.filter({ member.roleIds.contains($0.id) })
        let (allowRole, denyRole) = roleOverwrites.reduce(([], []) as (DiscordPermission, DiscordPermission), {cur, overwrite in
            return (cur.0.union(overwrite.allow), cur.1.union(overwrite.deny))
        })
        workingPermissions.subtract(denyRole)
        workingPermissions.formUnion(allowRole)

        if let memberOverwrite = self.permissionOverwrites[member.user.id] {
            workingPermissions.subtract(memberOverwrite.deny)
            workingPermissions.formUnion(memberOverwrite.allow)
        }

        if !workingPermissions.contains(.sendMessages) {
            // If they can't send messages, they automatically lose some permissions
            workingPermissions.subtract([.sendTTSMessages, .mentionEveryone, .attachFiles, .embedLinks])
        }

        if !workingPermissions.contains(.readMessages) {
            // If they can't read, they lose all channel based permissions
            workingPermissions.subtract(.allChannel)
        }

        if self is DiscordGuildTextChannel {
            // Text channels don't have voice permissions.
            workingPermissions.subtract(.voice)
        }

        return workingPermissions
    }
}

func guildChannel(fromObject channelObject: [String: Any],
                  guildID: GuildID?,
                  client: DiscordClient? = nil) -> DiscordGuildChannel? {
    guard let typeInt = channelObject["type"] as? Int,
          let type = DiscordChannelType(rawValue: typeInt) else {
        return nil
    }

    switch type {
    case .text:
        return DiscordGuildTextChannel(guildChannelObject: channelObject, guildID: guildID, client: client)
    case .voice:
        return DiscordGuildVoiceChannel(guildChannelObject: channelObject, guildID: guildID, client: client)
    case .category:
        return DiscordGuildChannelCategory(categoryObject: channelObject, guildID: guildID, client: client)
    default:
        logger.error("Unhandled guild channel in guildChannelFromObject")
        return nil
    }
}

func guildChannels(fromArray guildChannelArray: [[String: Any]],
                   guildID: GuildID?,
                   client: DiscordClient? = nil) -> [ChannelID: DiscordGuildChannel] {
    var guildChannels = [ChannelID: DiscordGuildChannel]()

    for guildChannel in guildChannelArray.compactMap({ return guildChannel(fromObject: $0,
                                                                           guildID: guildID,
                                                                           client: client) }) {
        guildChannels[guildChannel.id] = guildChannel
    }

    return guildChannels
}

/// Represents a guild channel.
public struct DiscordGuildTextChannel : DiscordTextChannel, DiscordGuildChannel {
    // MARK: Guild Text Channel Properties

    /// The snowflake id of the channel.
    public let id: ChannelID

    /// The snowflake id of the guild this channel is on.
    public let guildId: GuildID

    /// Reference to the client.
    public weak var client: DiscordClient?

    /// The last message received on this channel.
    ///
    /// **NOTE** Currently is not being updated.
    public var lastMessageId: MessageID

    /// The name of this channel.
    public var name: String

    /// The parent category for this channel.
    public var parentId: ChannelID?

    /// The permissions specifics to this channel.
    public var permissionOverwrites: [OverwriteID: DiscordPermissionOverwrite]

    /// The position of this channel. Mostly for UI purpose.
    public var position: Int

    /// The topic of this channel, if this is a text channel.
    public var topic: String

    /// If this channel is NSFW
    public var nsfw: Bool
    
    init(guildChannelObject: [String: Any], guildID: GuildID?, client: DiscordClient? = nil) {
        id = Snowflake(guildChannelObject["id"] as? String) ?? 0
        guildId = guildID ?? Snowflake(guildChannelObject["guild_id"] as? String) ?? 0
        lastMessageId = Snowflake(guildChannelObject["last_message_id"] as? String) ?? 0
        name = guildChannelObject.get("name", or: "")
        permissionOverwrites = DiscordPermissionOverwrite.overwritesFromArray(
            guildChannelObject.get("permission_overwrites", or: JSONArray()))
        position = guildChannelObject.get("position", or: 0)
        topic = guildChannelObject.get("topic", or: "")
        parentId = Snowflake(guildChannelObject.get("parent_id", or: ""))
        nsfw = guildChannelObject.get("nsfw", or: false)
        self.client = client
    }
}

/// Represents a voice channel.
public struct DiscordGuildVoiceChannel : DiscordGuildChannel {
    // MARK: Guild Voice Channel Properties

    /// The snowflake id of the channel.
    public let id: ChannelID

    /// The snowflake id of the guild this channel is on.
    public let guildId: GuildID

    /// The bitrate of this channel, if this is a voice channel.
    public var bitrate: Int

    /// Reference to the client.
    public weak var client: DiscordClient?

    /// The name of this channel.
    public var name: String

    /// The parent category for this channel.
    public var parentId: ChannelID?

    /// The permissions specifics to this channel.
    public var permissionOverwrites: [OverwriteID: DiscordPermissionOverwrite]

    /// The position of this channel. Mostly for UI purpose.
    public var position: Int

    /// The user limit of this channel, if this is a voice channel.
    public var userLimit: Int

    init(guildChannelObject: [String: Any], guildID: GuildID?, client: DiscordClient? = nil) {
        id = Snowflake(guildChannelObject["id"] as? String) ?? 0
        guildId = guildID ?? Snowflake(guildChannelObject["guild_id"] as? String) ?? 0
        bitrate = guildChannelObject.get("bitrate", or: 0) as Int
        name = guildChannelObject.get("name", or: "")
        permissionOverwrites = DiscordPermissionOverwrite.overwritesFromArray(
            guildChannelObject.get("permission_overwrites", or: JSONArray()))
        position = guildChannelObject.get("position", or: 0)
        userLimit = guildChannelObject.get("user_limit", or: 0) as Int
        parentId = Snowflake(guildChannelObject.get("parent_id", or: ""))
        self.client = client
    }
}

// TODO make sure this is correct when category types are documented.
/// A Category channel.
public struct DiscordGuildChannelCategory : DiscordGuildChannel {
    /// The id for this category.
    public let id: ChannelID

    /// The id for this channel category.
    public let guildId: GuildID

    /// The name for this channel.
    public let name: String

    /// The parent category of this channel.
    public let parentId = nil as ChannelID?

    /// The position of this channel.
    public let position: Int

    // TODO if permissions here start affecting child channels, fix permissions. Currently it looks like
    // Discord syncs permissions with child channels and child permissions are what matters.
    /// The permission overwrites for this channel.
    public let permissionOverwrites: [OverwriteID: DiscordPermissionOverwrite]

    /// Reference to the client.
    public weak var client: DiscordClient?

    init(categoryObject: [String: Any], guildID: GuildID?, client: DiscordClient?) {
        id = categoryObject.getSnowflake()
        guildId = guildID ?? categoryObject.getSnowflake(key: "guild_id")
        name = categoryObject.get("name", or: "")
        permissionOverwrites = DiscordPermissionOverwrite.overwritesFromArray(
            categoryObject.get("permission_overwrites", or: JSONArray()))
        position = categoryObject.get("position", or: 0)
        self.client = client
    }
}
