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

    **NOTE**: Callbacks from the default implementations are *NOT* executed on the client's handleQueue. So it is important
    that if you make modifications to the client inside of a callback, you first dispatch back on the handleQueue.
*/
public protocol DiscordEndpointConsumer : DiscordUserActor {
    // MARK: Channels

    /**
        Adds a pinned message.

        - parameter messageId: The message that is to be pinned's snowflake id
        - parameter on: The channel that we are adding on
        - parameter callback: An optional callback indicating whether the pinned message was added.
    */
    func addPinnedMessage(_ messageId: String, on channelId: String, callback: ((Bool) -> Void)?)

    /**
        Deletes a bunch of messages at once.

        - parameter messages: An array of message snowflake ids that are to be deleted
        - parameter on: The channel that we are deleting on
        - parameter callback: An optional callback indicating whether the messages were deleted.
    */
    func bulkDeleteMessages(_ messages: [String], on channelId: String, callback: ((Bool) -> Void)?)

    /**
        Creates an invite for a channel/guild.

        - parameter for: The channel that we are creating for
        - parameter options: An array of `DiscordEndpointOptions.CreateInvite` options
        - parameter callback: The callback function. Takes an optional `DiscordInvite`
    */
    func createInvite(for channelId: String, options: [DiscordEndpointOptions.CreateInvite],
                      callback: @escaping (DiscordInvite?) -> Void)

    /**
        Deletes the specified channel.

        - parameter channelId: The snowflake id of the channel
        - parameter callback: An optional callback indicating whether the channel was deleted.
    */
    func deleteChannel(_ channelId: String, callback: ((Bool) -> Void)?)

    /**
        Deletes a channel permission

        - parameter overwriteId: The permission overwrite that is to be deleted's snowflake id
        - parameter on: The channel that we are deleting on
        - parameter callback: An optional callback indicating whether the permission was deleted.
    */
    func deleteChannelPermission(_ overwriteId: String, on channelId: String, callback: ((Bool) -> Void)?)

    /**
        Deletes a single message

        - parameter messageId: The message that is to be deleted's snowflake id
        - parameter on: The channel that we are deleting on
        - parameter callback: An optional callback indicating whether the message was deleted.
    */
    func deleteMessage(_ messageId: String, on channelId: String, callback: ((Bool) -> Void)?)

    /**
        Unpins a message.

        - parameter messageId: The message that is to be unpinned's snowflake id
        - parameter on: The channel that we are unpinning on
        - parameter callback: An optional callback indicating whether the message was unpinned.
    */
    func deletePinnedMessage(_ messageId: String, on channelId: String, callback: ((Bool) -> Void)?)

    /**
        Gets the specified channel.

        - parameter channelId: The snowflake id of the channel
        - parameter callback: The callback function containing an optional `DiscordGuildChannel`
    */
    func getChannel(_ channelId: String, callback: @escaping (DiscordGuildChannel?) -> Void)

    /**
        Edits a message

        - parameter messageId: The message that is to be edited's snowflake id
        - parameter on: The channel that we are editing on
        - parameter content: The new content of the message
        - parameter callback: An optional callback containing the edited message, if successful.
    */
    func editMessage(_ messageId: String, on channelId: String, content: String, callback: ((DiscordMessage?) -> Void)?)

    /**
        Edits the specified permission overwrite.

        - parameter permissionOverwrite: The new DiscordPermissionOverwrite
        - parameter on: The channel that we are editing on
        - parameter callback: An optional callback indicating whether the edit was successful.
    */
    func editChannelPermission(_ permissionOverwrite: DiscordPermissionOverwrite, on channelId: String,
                               callback: ((Bool) -> Void)?)

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
        Modifies the specified channel.

        - parameter channelId: The snowflake id of the channel
        - parameter options: An array of `DiscordEndpointOptions.ModifyChannel` options
        - parameter callback: An optional callback containing the edited guild channel, if successful.
    */
    func modifyChannel(_ channelId: String, options: [DiscordEndpointOptions.ModifyChannel],
                       callback: ((DiscordGuildChannel?) -> Void)?)

    /**
        Gets the pinned messages for a channel.

        - parameter for: The channel that we are getting the pinned messages for
        - parameter callback: The callback function, taking an array of `DiscordMessages`
    */
    func getPinnedMessages(for channelId: String, callback: @escaping ([DiscordMessage]) -> Void)

    /**
        Sends a message to the specified channel.

        - parameter content: The content of the message.
        - parameter to: The snowflake id of the channel to send to.
        - parameter tts: Whether this message should be read a text-to-speech message.
        - parameter embed: An optional embed for this message.
        - parameter callback: An optional callback containing the message, if successful.
    */
    @available(*, deprecated: 3.1, message: "Will be removed in 3.2, use the new sendMessage")
    func sendMessage(_ message: String, to channelId: String, tts: Bool, embed: DiscordEmbed?,
                     callback: ((DiscordMessage?) -> Void)?)

    /**
        Sends a message with an optional file and embed to the specified channel.

        - parameter message: The message to send.
        - parameter file: The file to send.
        - parameter to: The snowflake id of the channel to send to.
        - parameter tts: Whether this message should be read a text-to-speech message.
        - parameter callback: An optional callback containing the message, if successful.
    */
    func sendMessage(_ message: String, file: DiscordFileUpload?, embed: DiscordEmbed?, to channelId: String,
                     tts: Bool, callback: ((DiscordMessage?) -> Void)?)

    /**
        Triggers typing on the specified channel.

        - parameter on: The snowflake id of the channel to send to
        - parameter callback: An optional callback indicating whether typing was triggered.
    */
    func triggerTyping(on channelId: String, callback: ((Bool) -> Void)?)

    // MARK: Guilds

    /**
        Adds a role to a guild member.

        - parameter roleId: The id of the role to add.
        - parameter to: The id of the member to add this role to.
        - parameter on: The id of the guild this member is on.
        - parameter with: The token to authenticate to Discord with.
        - parameter callback: An optional callback indicating whether the role was added successfully.
    */
    func addGuildMemberRole(_ roleId: String, to userId: String, on guildId: String, callback: ((Bool) -> Void)?)

    /**
        Creates a guild channel.

        - parameter guildId: The snowflake id of the guild
        - parameter options: An array of `DiscordEndpointOptions.GuildCreateChannel` options
        - parameter callback: An optional callback containing the new channel, if successful.
    */
    func createGuildChannel(on guildId: String, options: [DiscordEndpointOptions.GuildCreateChannel],
                            callback: ((DiscordGuildChannel?) -> Void)?)

    /**
        Creates a role on a guild.

        - parameter on: The snowflake id of the guild.
        - parameter withOptions: The options for the new role. Optional in the default implementation.
        - parameter callback: The callback function, taking an optional `DiscordRole`.
    */
    func createGuildRole(on guildId: String, withOptions options: [DiscordEndpointOptions.CreateRole],
                         callback: @escaping (DiscordRole?) -> Void)

    /**
        Deletes the specified guild.

        - parameter guildId: The snowflake id of the guild
        - parameter callback: An optional callback containing the deleted guild, if successful.
    */
    func deleteGuild(_ guildId: String, callback: ((DiscordGuild?) -> Void)?)

    /**
        Gets the bans on a guild.

        - parameter for: The snowflake id of the guild
        - parameter callback: The callback function, taking an array of `DiscordBan`
    */
    func getGuildBans(for guildId: String, callback: @escaping ([DiscordBan]) -> Void)

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
        Gets the roles on a guild.

        - parameter for: The snowflake id of the guild
        - parameter callback: The callback function, taking an array of `DiscordRole`
    */
    func getGuildRoles(for guildId: String, callback: @escaping ([DiscordRole]) -> Void)

    /**
        Creates a guild ban.

        - parameter userId: The snowflake id of the user
        - parameter on: The snowflake id of the guild
        - parameter deleteMessageDays: The number of days to delete this user's messages
        - parameter callback: An optional callback indicating whether the ban was successful.
    */
    func guildBan(userId: String, on guildId: String, deleteMessageDays: Int, callback: ((Bool) -> Void)?)

    /**
        Modifies the specified guild.

        - parameter guildId: The snowflake id of the guild
        - parameter options: An array of `DiscordEndpointOptions.ModifyGuild` options
        - parameter callback: An optional callback containing the modified guild, if successful.
    */
    func modifyGuild(_ guildId: String, options: [DiscordEndpointOptions.ModifyGuild],
                     callback: ((DiscordGuild?) -> Void)?)

    /**
        Modifies the position of a channel.

        - parameter on: The snowflake id of the guild
        - parameter channelPositions: An array of channels that should be reordered. Should contain a dictionary
                                      in the form `["id": channelId, "position": position]`
        - parameter callback: An optional callback containing the modified channels, if successful.
    */
    func modifyGuildChannelPositions(on guildId: String, channelPositions: [[String: Any]],
                                     callback: (([DiscordGuildChannel]) -> Void)?)

    /**
        Edits the specified role.

        - parameter permissionOverwrite: The new DiscordRole
        - parameter on: The guild that we are editing on
        - parameter callback: An optional callback containing the modified role, if successful.
    */
    func modifyGuildRole(_ role: DiscordRole, on guildId: String, callback: ((DiscordRole?) -> Void)?)

    /**
        Removes a guild ban.

        - parameter for: The snowflake id of the user
        - parameter on: The snowflake id of the guild
        - parameter callback: An optional callback indicating whether the ban was successfully removed.
    */
    func removeGuildBan(for userId: String, on guildId: String, callback: ((Bool) -> Void)?)

    /**
        Removes a role from a guild member.

        - parameter roleId: The id of the role to add.
        - parameter from: The id of the member to add this role to.
        - parameter on: The id of the guild this member is on.
        - parameter with: The token to authenticate to Discord with.
        - parameter callback: An optional callback indicating whether the role was removed successfully.
    */
    func removeGuildMemberRole(_ roleId: String, from userId: String, on guildId: String, callback: ((Bool) -> Void)?)

    /**
        Removes a guild role.

        - parameter roleId: The snowflake id of the role
        - parameter on: The snowflake id of the guild
        - parameter callback: An optional callback containing the removed role, if successful.
    */
    func removeGuildRole(_ roleId: String, on guildId: String, callback: ((DiscordRole?) -> Void)?)

    // MARK: Webhooks

    /**
        Creates a webhook for a given channel.

        - parameter forChannel: The channel to create the webhook for
        - parameter options: The options for this webhook
        - parameter callback: A callback that returns the webhook created, if successful.
    */
    func createWebhook(forChannel channelId: String, options: [DiscordEndpointOptions.WebhookOption],
                       callback: @escaping (DiscordWebhook?) -> Void)

    /**
        Deletes a webhook. The user must be the owner of the webhook.

        - parameter webhookId: The id of the webhook
        - paramter callback: An optional callback function that indicates whether the delete was successful
    */
    func deleteWebhook(_ webhookId: String, callback: ((Bool) -> Void)?)

    /**
        Gets the specified webhook.

        - parameter webhookId: The snowflake id of the webhook
        - parameter callback: The callback function containing an optional `DiscordToken`
    */
    func getWebhook(_ webhookId: String, callback: @escaping (DiscordWebhook?) -> Void)

    /**
        Gets the webhooks for a specified channel.

        - parameter forChannel: The snowflake id of the channel.
        - parameter callback: The callback function taking an array of `DiscordWebhook`s
    */
    func getWebhooks(forChannel channelId: String, callback: @escaping ([DiscordWebhook]) -> Void)

    /**
        Gets the webhooks for a specified guild.

        - parameter forGuild: The snowflake id of the guild.
        - parameter callback: The callback function taking an array of `DiscordWebhook`s
    */
    func getWebhooks(forGuild guildId: String, callback: @escaping ([DiscordWebhook]) -> Void)

    /**
        Modifies a webhook.

        - parameter webhookId: The webhook to modify
        - parameter options: The options for this webhook
        - parameter callback: A callback that returns the updated webhook, if successful.
    */
    func modifyWebhook(_ webhookId: String, options: [DiscordEndpointOptions.WebhookOption],
                       callback: @escaping (DiscordWebhook?) -> Void)

    // MARK: Invites

    /**
        Accepts an invite.

        - parameter invite: The invite code to accept
        - parameter callback: An optional callback containing the accepted invite, if successful
    */
    func acceptInvite(_ invite: String, callback: ((DiscordInvite?) -> Void)?)

    /**
        Deletes an invite.

        - parameter invite: The invite code to delete
        - parameter callback: An optional callback containing the deleted invite, if successful
    */
    func deleteInvite(_ invite: String, callback: ((DiscordInvite?) -> Void)?)

    /**
        Gets an invite.

        - parameter invite: The invite code to accept
        - parameter callback: The callback function, takes an optional `DiscordInvite`
    */
    func getInvite(_ invite: String, callback: @escaping (DiscordInvite?) -> Void)

    // MARK: Users

    /**
        Creates a direct message channel with a user.

        - parameter with: The user that the channel will be opened with's snowflake id
        - parameter user: Our snowflake id
        - parameter callback: The callback function. Takes an optional `DiscordDMChannel`
    */
    func createDM(with: String, callback: @escaping (DiscordDMChannel?) -> Void)

    /**
        Gets the direct message channels for a user.

        - parameter user: Our snowflake id
        - parameter callback: The callback function, taking a dictionary of `DiscordDMChannel` associated by
                              the recipient's id
    */
    func getDMs(callback: @escaping ([String: DiscordDMChannel]) -> Void)

    /**
        Gets guilds the user is in.

        - parameter user: Our snowflake id
        - parameter callback: The callback function, taking a dictionary of `DiscordUserGuild` associated by guild id
    */
    func getGuilds(callback: @escaping ([String: DiscordUserGuild]) -> Void)

    // MARK: Misc

    /**
        Creates a url that can be used to authorize a bot.

        - parameter with: An array of `DiscordPermission` that this bot should have
    */
    func getBotURL(with permissions: [DiscordPermission]) -> URL?
}

public extension DiscordEndpointConsumer {
    /// Default implementation
    public func acceptInvite(_ invite: String, callback: ((DiscordInvite?) -> Void)? = nil) {
        DiscordEndpoint.acceptInvite(invite, with: token, callback: callback)
    }

    /// Default implementation
    public func addPinnedMessage(_ messageId: String, on channelId: String, callback: ((Bool) -> Void)? = nil) {
        DiscordEndpoint.addPinnedMessage(messageId, on: channelId, with: token, callback: callback)
    }

    /// Default implementation
    public func addGuildMemberRole(_ roleId: String, to userId: String, on guildId: String,
                                   callback: ((Bool) -> Void)?) {
        DiscordEndpoint.addGuildMemberRole(roleId, to: userId, on: guildId, with: token, callback: callback)
    }

    /// Default implementation
    public func bulkDeleteMessages(_ messages: [String], on channelId: String, callback: ((Bool) -> Void)? = nil) {
        DiscordEndpoint.bulkDeleteMessages(messages, on: channelId, with: token, callback: callback)
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
    public func createGuildChannel(on guildId: String, options: [DiscordEndpointOptions.GuildCreateChannel],
                                   callback: ((DiscordGuildChannel?) -> Void)? = nil) {
        DiscordEndpoint.createGuildChannel(guildId, options: options, with: token, callback: callback)
    }

    /// Default implementation
    public func createGuildRole(on guildId: String, withOptions options: [DiscordEndpointOptions.CreateRole] = [],
                                callback: @escaping (DiscordRole?) -> Void) {
        DiscordEndpoint.createGuildRole(on: guildId, withOptions: options, with: token, callback: callback)
    }

    /// Default implementation
    public func createWebhook(forChannel channelId: String, options: [DiscordEndpointOptions.WebhookOption],
                              callback: @escaping (DiscordWebhook?) -> Void = {_ in }) {
        DiscordEndpoint.createWebhook(forChannel: channelId, with: token, options: options, callback: callback)
    }

    /// Default implementation
    public func deleteChannel(_ channelId: String, callback: ((Bool) -> Void)? = nil) {
        DiscordEndpoint.deleteChannel(channelId, with: token, callback: callback)
    }

    /// Default implementation
    public func deleteChannelPermission(_ overwriteId: String, on channelId: String, callback: ((Bool) -> Void)? = nil) {
        DiscordEndpoint.deleteChannelPermission(overwriteId, on: channelId, with: token, callback: callback)
    }

    /// Default implementation
    public func deleteGuild(_ guildId: String, callback: ((DiscordGuild?) -> Void)? = nil) {
        DiscordEndpoint.deleteGuild(guildId, with: token, callback: callback)
    }

    /// Default implementation
    public func deleteInvite(_ invite: String, callback: ((DiscordInvite?) -> Void)? = nil) {
        DiscordEndpoint.deleteInvite(invite, with: token, callback: callback)
    }

    /// Default implementation
    public func deleteMessage(_ messageId: String, on channelId: String, callback: ((Bool) -> Void)? = nil) {
        DiscordEndpoint.deleteMessage(messageId, on: channelId, with: token, callback: callback)
    }

    /// Default implementation
    public func deletePinnedMessage(_ messageId: String, on channelId: String, callback: ((Bool) -> Void)? = nil) {
        DiscordEndpoint.deletePinnedMessage(messageId, on: channelId, with: token, callback: callback)
    }

    /// Default implementation
    public func deleteWebhook(_ webhookId: String, callback: ((Bool) -> Void)? = nil) {
        DiscordEndpoint.deleteWebhook(webhookId, with: token, callback: callback)
    }

    /// Default implementation
    public func editMessage(_ messageId: String, on channelId: String, content: String,
                            callback: ((DiscordMessage?) -> Void)? = nil) {
        DiscordEndpoint.editMessage(messageId, on: channelId, content: content, with: token, callback: callback)
    }

    /// Default implementation
    public func editChannelPermission(_ permissionOverwrite: DiscordPermissionOverwrite, on channelId: String,
                                      callback: ((Bool) -> Void)? = nil) {
        DiscordEndpoint.editChannelPermission(permissionOverwrite, on: channelId, with: token, callback: callback)
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
    public func getGuildBans(for guildId: String, callback: @escaping ([DiscordBan]) -> Void) {
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
    public func getWebhook(_ webhookId: String, callback: @escaping (DiscordWebhook?) -> Void) {
        DiscordEndpoint.getWebhook(webhookId, with: token, callback: callback)
    }

    /// Default implementation
    public func getWebhooks(forChannel channelId: String, callback: @escaping ([DiscordWebhook]) -> Void) {
        DiscordEndpoint.getWebhooks(forChannel: channelId, with: token, callback: callback)
    }

    /// Default implementation
    public func getWebhooks(forGuild guildId: String, callback: @escaping ([DiscordWebhook]) -> Void) {
        DiscordEndpoint.getWebhooks(forGuild: guildId, with: token, callback: callback)
    }

    /// Default implementation
    public func guildBan(userId: String, on guildId: String, deleteMessageDays: Int = 7,
                         callback: ((Bool) -> Void)? = nil) {
        DiscordEndpoint.guildBan(userId: userId, on: guildId, deleteMessageDays: deleteMessageDays,
            with: token, callback: callback)
    }

    /// Default implementation
    public func getPinnedMessages(for channelId: String, callback: @escaping ([DiscordMessage]) -> Void) {
        DiscordEndpoint.getPinnedMessages(for: channelId, with: token, callback: callback)
    }

    /// Default implementation
    public func modifyChannel(_ channelId: String, options: [DiscordEndpointOptions.ModifyChannel],
                              callback: ((DiscordGuildChannel?) -> Void)? = nil) {
        DiscordEndpoint.modifyChannel(channelId, options: options, with: token, callback: callback)
    }

    /// Default implementation
    public func modifyGuild(_ guildId: String, options: [DiscordEndpointOptions.ModifyGuild],
                            callback: ((DiscordGuild?) -> Void)? = nil) {
        DiscordEndpoint.modifyGuild(guildId, options: options, with: token, callback: callback)
    }

    /// Default implementation
    public func modifyGuildChannelPositions(on guildId: String, channelPositions: [[String: Any]],
                                            callback: (([DiscordGuildChannel]) -> Void)? = nil) {
        DiscordEndpoint.modifyGuildChannelPositions(on: guildId, channelPositions: channelPositions,
            with: token, callback: callback)
    }

    /// Default implementation
    public func modifyGuildRole(_ role: DiscordRole, on guildId: String, callback: ((DiscordRole?) -> Void)? = nil) {
        DiscordEndpoint.modifyGuildRole(role, on: guildId, with: token, callback: callback)
    }

    /// Default implementation
    public func modifyWebhook(_ webhookId: String, options: [DiscordEndpointOptions.WebhookOption],
            callback: @escaping (DiscordWebhook?) -> Void = {_ in }) {
        DiscordEndpoint.modifyWebhook(webhookId, with: token, options: options, callback: callback)
    }

    /// Default implementation
    public func removeGuildBan(for userId: String, on guildId: String, callback: ((Bool) -> Void)? = nil) {
        DiscordEndpoint.removeGuildBan(for: userId, on: guildId, with: token, callback: callback)
    }

    /// Default implementation.
    public func removeGuildMemberRole(_ roleId: String, from userId: String, on guildId: String,
                                      callback: ((Bool) -> Void)?) {
        DiscordEndpoint.removeGuildMemberRole(roleId, from: userId, on: guildId, with: token, callback: callback)
    }

    /// Default implementation
    public func removeGuildRole(_ roleId: String, on guildId: String, callback: ((DiscordRole?) -> Void)? = nil) {
        DiscordEndpoint.removeGuildRole(roleId, on: guildId, with: token, callback: callback)
    }

    /// Default implementation
    public func sendMessage(_ message: String, to channelId: String, tts: Bool = false,
                            embed: DiscordEmbed? = nil, callback: ((DiscordMessage?) -> Void)? = nil) {
        DiscordEndpoint.sendMessage(message, with: token, to: channelId, tts: tts, embed: embed, callback: callback)
    }

    /// Default implementation
    public func sendMessage(_ message: String, file: DiscordFileUpload? = nil, embed: DiscordEmbed? = nil,
                            to channelId: String, tts: Bool = false, callback: ((DiscordMessage?) -> Void)? = nil) {
        DiscordEndpoint.sendMessage(message, file: file, embed: embed, with: token, to: channelId, tts: tts,
                                    callback: callback)
    }

    /// Default implementation
    public func triggerTyping(on channelId: String, callback: ((Bool) -> Void)? = nil) {
        DiscordEndpoint.triggerTyping(on: channelId, with: token, callback: callback)
    }
}
