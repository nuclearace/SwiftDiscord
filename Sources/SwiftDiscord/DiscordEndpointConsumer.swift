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

/**
    Protocol that declares a type will be a consumer of the Discord REST API.

    This is where a `DiscordClient` gets the methods that interact with the REST API.
*/
public protocol DiscordEndpointConsumer : DiscordUserActor {
    // MARK: Methods

    /**
        Accepts an invite.

        - parameter invite: The invite code to accept
    */
    func acceptInvite(_ invite: String)

    /**
        Adds a pinned message.

        - parameter messageId: The message that is to be pinned's snowflake id
        - parameter on: The channel that we are adding on
    */
    func addPinnedMessage(_ messageId: String, on channelId: String)

    /**
        Deletes a bunch of messages at once.

        - parameter messages: An array of message snowflake ids that are to be deleted
        - parameter on: The channel that we are deleting on
    */
    func bulkDeleteMessages(_ messages: [String], on channelId: String)

    /**
        Creates a direct message channel with a user.

        - parameter with: The user that the channel will be opened with's snowflake id
        - parameter user: Our snowflake id
        - parameter callback: The callback function. Takes an optional `DiscordDMChannel`
    */
    func createDM(with: String, callback: @escaping (DiscordDMChannel?) -> Void)

    /**
        Creates an invite for a channel/guild.

        - parameter for: The channel that we are creating for
        - parameter options: An array of `DiscordEndpointOptions.CreateInvite` options
        - parameter callback: The callback function. Takes an optional `DiscordInvite`
    */
    func createInvite(for channelId: String, options: [DiscordEndpointOptions.CreateInvite],
        callback: @escaping (DiscordInvite?) -> Void)

    /**
        Creates a guild channel.

        - parameter guildId: The snowflake id of the guild
        - parameter options: An array of `DiscordEndpointOptions.GuildCreateChannel` options
    */
    func createGuildChannel(on guildId: String, options: [DiscordEndpointOptions.GuildCreateChannel])

    /**
        Creates a role on a guild.

        - parameter on: The snowflake id of the guild
        - parameter callback: The callback function, taking an optional `DiscordRole`
    */
    func createGuildRole(on guildId: String, callback: @escaping (DiscordRole?) -> Void)

    /**
        Deletes the specified channel.

        - parameter channelId: The snowflake id of the channel
    */
    func deleteChannel(_ channelId: String)

    /**
        Deletes a channel permission

        - parameter overwriteId: The permission overwrite that is to be deleted's snowflake id
        - parameter on: The channel that we are deleting on
    */
    func deleteChannelPermission(_ overwriteId: String, on channelId: String)

    /**
        Deletes the specified guild.

        - parameter guildId: The snowflake id of the guild
    */
    func deleteGuild(_ guildId: String)

    /**
        Deletes a single message

        - parameter messageId: The message that is to be deleted's snowflake id
        - parameter on: The channel that we are deleting on
    */
    func deleteMessage(_ messageId: String, on channelId: String)

    /**
        Unpins a message.

        - parameter messageId: The message that is to be unpinned's snowflake id
        - parameter on: The channel that we are unpinning on
    */
    func deletePinnedMessage(_ messageId: String, on channelId: String)

    /**
        Edits a message

        - parameter messageId: The message that is to be edited's snowflake id
        - parameter on: The channel that we are editing on
        - parameter content: The new content of the message
    */
    func editMessage(_ messageId: String, on channelId: String, content: String)

    /**
        Edits the specified permission overwrite.

        - parameter permissionOverwrite: The new DiscordPermissionOverwrite
        - parameter on: The channel that we are editing on
    */
    func editChannelPermission(_ permissionOverwrite: DiscordPermissionOverwrite, on channelId: String)

    /**
        Creates a url that can be used to authorize a bot.

        - parameter with: An array of `DiscordPermission` that this bot should have
    */
    func getBotURL(with permissions: [DiscordPermission]) -> URL?

    /**
        Gets the direct message channels for a user.

        - parameter user: Our snowflake id
        - parameter callback: The callback function, taking a dictionary of `DiscordDMChannel` associated by
                              the recipient's id
    */
    func getDMs(callback: @escaping ([String: DiscordDMChannel]) -> Void)

    /**
        Gets the specified channel.

        - parameter channelId: The snowflake id of the channel
        - parameter callback: The callback function containing an optional `DiscordGuildChannel`
    */
    func getChannel(_ channelId: String, callback: @escaping (DiscordGuildChannel?) -> Void)

    /**
        Gets the bans on a guild.

        - parameter for: The snowflake id of the guild
        - parameter callback: The callback function, taking an array of `DiscordUser`
    */
    func getGuildBans(for guildId: String, callback: @escaping ([DiscordUser]) -> Void)

    /**
        Gets the channels on a guild.

        - parameter guildId: The snowflake id of the guild
        - parameter callback: The callback function, taking an array of `DiscordGuildChannel`
    */
    func getGuildChannels(_ guildId: String, callback: @escaping ([DiscordGuildChannel]) -> Void)

    /**
        Gets the specified guild member.

        - parameter by: The snowflake id of the member
        - parameter on: The snowflake id of the guild
        - parameter callback: The callback function containing an optional `DiscordGuildMember`
    */
    func getGuildMember(by id: String, on guildId: String, callback: @escaping (DiscordGuildMember?) -> Void)

    /**
        Gets the members on a guild.

        - parameter on: The snowflake id of the guild
        - parameter options: An array of `DiscordEndpointOptions.GuildGetMembers` options
        - parameter callback: The callback function, taking an array of `DiscordGuildMember`
    */
    func getGuildMembers(on guildId: String, options: [DiscordEndpointOptions.GuildGetMembers],
        callback: @escaping ([DiscordGuildMember]) -> Void)

    /**
        Gets guilds the user is in.

        - parameter user: Our snowflake id
        - parameter callback: The callback function, taking a dictionary of `DiscordUserGuild` associated by guild id
    */
    func getGuilds(callback: @escaping ([String: DiscordUserGuild]) -> Void)

    /**
        Gets the roles on a guild.

        - parameter for: The snowflake id of the guild
        - parameter callback: The callback function, taking an array of `DiscordRole`
    */
    func getGuildRoles(for guildId: String, callback: @escaping ([DiscordRole]) -> Void)

    /**
        Gets an invite.

        - parameter invite: The invite code to accept
        - parameter callback: The callback function, takes an optional `DiscordInvite`
    */
    func getInvite(_ invite: String, callback: @escaping (DiscordInvite?) -> Void)

    /**
        Gets the invites for a channel.

        - parameter for: The channel that we are getting on
        - parameter callback: The callback function, taking an array of `DiscordInvite`
    */
    func getInvites(for channelId: String, callback: @escaping ([DiscordInvite]) -> Void)

    /**
        Gets a group of messages according to the specified options.

        - parameter for: The channel that we are getting on
        - parameter options: An array of `DiscordEndpointOptions.GetMessage` options
        - parameter callback: The callback function, taking an array of `DiscordMessages`
    */
    func getMessages(for channel: String, options: [DiscordEndpointOptions.GetMessage],
        callback: @escaping ([DiscordMessage]) -> Void)

    /**
        Gets the pinned messages for a channel.

        - parameter for: The channel that we are getting the pinned messages for
        - parameter callback: The callback function, taking an array of `DiscordMessages`
    */
    func getPinnedMessages(for channelId: String, callback: @escaping ([DiscordMessage]) -> Void)

    /**
        Creates a guild ban.

        - parameter userId: The snowflake id of the user
        - parameter on: The snowflake id of the guild
        - parameter deleteMessageDays: The number of days to delete this user's messages
    */
    func guildBan(userId: String, on guildId: String, deleteMessageDays: Int)

    /**
        Modifies the specified channel.

        - parameter channelId: The snowflake id of the channel
        - parameter options: An array of `DiscordEndpointOptions.ModifyChannel` options
    */
    func modifyChannel(_ channelId: String, options: [DiscordEndpointOptions.ModifyChannel])

    /**
        Modifies the specified guild.

        - parameter guildId: The snowflake id of the guild
        - parameter options: An array of `DiscordEndpointOptions.ModifyGuild` options
    */
    func modifyGuild(_ guildId: String, options: [DiscordEndpointOptions.ModifyGuild])

    /**
        Modifies the position of a channel.

        - parameter on: The snowflake id of the guild
        - parameter channelPositions: An array of channels that should be reordered. Should contain a dictionary
                                      in the form `["id": channelId, "position": position]`
    */
    func modifyGuildChannelPositions(on guildId: String, channelPositions: [[String: Any]])

    /**
        Edits the specified role.

        - parameter permissionOverwrite: The new DiscordRole
        - parameter on: The guild that we are editing on
    */
    func modifyGuildRole(_ role: DiscordRole, on guildId: String)

    /**
        Removes a guild ban.

        - parameter for: The snowflake id of the user
        - parameter on: The snowflake id of the guild
    */
    func removeGuildBan(for userId: String, on guildId: String)

    /**
        Removes a guild role.

        - parameter roleId: The snowflake id of the role
        - parameter on: The snowflake id of the guild
    */
    func removeGuildRole(_ roleId: String, on guildId: String)

    /**
        Sends a message to the specified channel.

        - parameter content: The content of the message
        - parameter to: The snowflake id of the channel to send to
        - parameter tts: Whether this message should be read a text-to-speech message
    */
    func sendMessage(_ message: String, to channelId: String, tts: Bool)

    /**
        Sends a file with an optional message to the specified channel.

        - parameter file: The file to send
        - parameter content: The content of the message
        - parameter to: The snowflake id of the channel to send to
        - parameter tts: Whether this message should be read a text-to-speech message
    */
    func sendFile(_ file: DiscordFileUpload, content: String, to channelId: String, tts: Bool)

    /**
        Triggers typing on the specified channel.

        - parameter on: The snowflake id of the channel to send to
    */
    func triggerTyping(on channelId: String)
}

public extension DiscordEndpointConsumer {
    /// Default implementation
    public func acceptInvite(_ invite: String) {
        DiscordEndpoint.acceptInvite(invite, with: token)
    }

    /// Default implementation
    public func addPinnedMessage(_ messageId: String, on channelId: String) {
        DiscordEndpoint.addPinnedMessage(messageId, on: channelId, with: token)
    }

    /// Default implementation
    public func bulkDeleteMessages(_ messages: [String], on channelId: String) {
        DiscordEndpoint.bulkDeleteMessages(messages, on: channelId, with: token)
    }

    /// Default implementation
    public func createDM(with: String, callback: @escaping (DiscordDMChannel?) -> Void) {
        DiscordEndpoint.createDM(with: with, user: user!.id, with: token, callback: callback)
    }

    /// Default implementation
    public func createInvite(for channelId: String, options: [DiscordEndpointOptions.CreateInvite],
            callback: @escaping (DiscordInvite?) -> Void) {
        DiscordEndpoint.createInvite(for: channelId, options: options, with: token, callback: callback)
    }

    /// Default implementation
    public func createGuildChannel(on guildId: String, options: [DiscordEndpointOptions.GuildCreateChannel]) {
        DiscordEndpoint.createGuildChannel(guildId, options: options, with: token)
    }

    /// Default implementation
    public func createGuildRole(on guildId: String, callback: @escaping (DiscordRole?) -> Void) {
        DiscordEndpoint.createGuildRole(on: guildId, with: token, callback: callback)
    }

    /// Default implementation
    public func deleteChannel(_ channelId: String) {
        DiscordEndpoint.deleteChannel(channelId, with: token)
    }

    /// Default implementation
    public func deleteChannelPermission(_ overwriteId: String, on channelId: String) {
        DiscordEndpoint.deleteChannelPermission(overwriteId, on: channelId, with: token)
    }

    /// Default implementation
    public func deleteGuild(_ guildId: String) {
        DiscordEndpoint.deleteGuild(guildId, with: token)
    }

    /// Default implementation
    public func deleteMessage(_ messageId: String, on channelId: String) {
        DiscordEndpoint.deleteMessage(messageId, on: channelId, with: token)
    }

    /// Default implementation
    public func deletePinnedMessage(_ messageId: String, on channelId: String) {
        DiscordEndpoint.deletePinnedMessage(messageId, on: channelId, with: token)
    }

    /// Default implementation
    public func editMessage(_ messageId: String, on channelId: String, content: String) {
        DiscordEndpoint.editMessage(messageId, on: channelId, content: content, with: token)
    }

    /// Default implementation
    public func editChannelPermission(_ permissionOverwrite: DiscordPermissionOverwrite, on channelId: String) {
        DiscordEndpoint.editChannelPermission(permissionOverwrite, on: channelId, with: token)
    }

    /// Default implementation
    public func getChannel(_ channelId: String, callback: @escaping (DiscordGuildChannel?) -> Void) {
        DiscordEndpoint.getChannel(channelId, with: token, callback: callback)
    }

    /// Default implementation
    public func getBotURL(with permissions: [DiscordPermission]) -> URL? {
        guard let user = self.user else { return nil }

        return DiscordOAuthEndpoint.createBotAddURL(for: user, with: permissions)
    }

    /// Default implementation
    public func getDMs(callback: @escaping ([String: DiscordDMChannel]) -> Void) {
        DiscordEndpoint.getDMs(user: user!.id, with: token, callback: callback)
    }

    /// Default implementation
    public func getGuildBans(for guildId: String, callback: @escaping ([DiscordUser]) -> Void) {
        DiscordEndpoint.getGuildBans(for: guildId, with: token, callback: callback)
    }

    /// Default implementation
    public func getGuildChannels(_ guildId: String, callback: @escaping ([DiscordGuildChannel]) -> Void) {
        DiscordEndpoint.getGuildChannels(guildId, with: token, callback: callback)
    }

    /// Default implementation
    public func getGuildMember(by id: String, on guildId: String, callback: @escaping (DiscordGuildMember?) -> Void) {
        DiscordEndpoint.getGuildMember(by: id, on: guildId, with: token, callback: callback)
    }

    /// Default implementation
    public func getGuildMembers(on guildId: String, options: [DiscordEndpointOptions.GuildGetMembers],
            callback: @escaping ([DiscordGuildMember]) -> Void) {
        DiscordEndpoint.getGuildMembers(on: guildId, options: options, with: token, callback: callback)
    }

    /// Default implementation
    public func getGuilds(callback: @escaping ([String: DiscordUserGuild]) -> Void) {
        DiscordEndpoint.getGuilds(user: user!.id, with: token, callback: callback)
    }

    /// Default implementation
    public func getGuildRoles(for guildId: String, callback: @escaping ([DiscordRole]) -> Void) {
        DiscordEndpoint.getGuildRoles(for: guildId, with: token, callback: callback)
    }

    /// Default implementation
    public func getInvite(_ invite: String, callback: @escaping (DiscordInvite?) -> Void) {
        DiscordEndpoint.getInvite(invite, with: token, callback: callback)
    }

    /// Default implementation
    public func getInvites(for channelId: String, callback: @escaping ([DiscordInvite]) -> Void) {
        return DiscordEndpoint.getInvites(for: channelId, with: token, callback: callback)
    }

    /// Default implementation
    public func getMessages(for channelId: String, options: [DiscordEndpointOptions.GetMessage] = [],
            callback: @escaping ([DiscordMessage]) -> Void) {
        DiscordEndpoint.getMessages(for: channelId, with: token, options: options, callback: callback)
    }

    /// Default implementation
    public func guildBan(userId: String, on guildId: String, deleteMessageDays: Int = 7) {
        DiscordEndpoint.guildBan(userId: userId, on: guildId, deleteMessageDays: deleteMessageDays, with: token)
    }

    /// Default implementation
    public func getPinnedMessages(for channelId: String, callback: @escaping ([DiscordMessage]) -> Void) {
        DiscordEndpoint.getPinnedMessages(for: channelId, with: token, callback: callback)
    }

    /// Default implementation
    public func modifyChannel(_ channelId: String, options: [DiscordEndpointOptions.ModifyChannel]) {
        DiscordEndpoint.modifyChannel(channelId, options: options, with: token)
    }

    /// Default implementation
    public func modifyGuild(_ guildId: String, options: [DiscordEndpointOptions.ModifyGuild]) {
        DiscordEndpoint.modifyGuild(guildId, options: options, with: token)
    }

    /// Default implementation
    public func modifyGuildChannelPositions(on guildId: String, channelPositions: [[String: Any]]) {
        DiscordEndpoint.modifyGuildChannelPositions(on: guildId, channelPositions: channelPositions,
            with: token)
    }

    /// Default implementation
    public func modifyGuildRole(_ role: DiscordRole, on guildId: String) {
        DiscordEndpoint.modifyGuildRole(role, on: guildId, with: token)
    }

    /// Default implementation
    public func removeGuildBan(for userId: String, on guildId: String) {
        DiscordEndpoint.removeGuildBan(for: userId, on: guildId, with: token)
    }

    /// Default implementation
    public func removeGuildRole(_ roleId: String, on guildId: String) {
        DiscordEndpoint.removeGuildRole(roleId, on: guildId, with: token)
    }

    /// Default implementation
    public func sendMessage(_ message: String, to channelId: String, tts: Bool = false) {
        DiscordEndpoint.sendMessage(message, with: token, to: channelId, tts: tts)
    }

    /// Default implementation
    public func sendFile(_ file: DiscordFileUpload, content: String, to channelId: String, tts: Bool = false) {
        DiscordEndpoint.sendFile(file, content: content, with: token, to: channelId, tts: tts)
    }

    /// Default implementation
    public func triggerTyping(on channelId: String) {
        DiscordEndpoint.triggerTyping(on: channelId, with: token)
    }
}
