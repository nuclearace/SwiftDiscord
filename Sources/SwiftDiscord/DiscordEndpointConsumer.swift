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
    func addPinnedMessage(_ messageId: String, on channelId: String, callback: ((Bool) -> ())?)

    /**
        Deletes a bunch of messages at once.

        - parameter messages: An array of message snowflake ids that are to be deleted
        - parameter on: The channel that we are deleting on
        - parameter callback: An optional callback indicating whether the messages were deleted.
    */
    func bulkDeleteMessages(_ messages: [String], on channelId: String, callback: ((Bool) -> ())?)

    /**
        Creates an invite for a channel/guild.

        - parameter for: The channel that we are creating for
        - parameter options: An array of `DiscordEndpointOptions.CreateInvite` options
        - parameter callback: The callback function. Takes an optional `DiscordInvite`
    */
    func createInvite(for channelId: String, options: [DiscordEndpointOptions.CreateInvite],
                      callback: @escaping (DiscordInvite?) -> ())

    /**
        Deletes the specified channel.

        - parameter channelId: The snowflake id of the channel
        - parameter callback: An optional callback indicating whether the channel was deleted.
    */
    func deleteChannel(_ channelId: String, callback: ((Bool) -> ())?)

    /**
        Deletes a channel permission

        - parameter overwriteId: The permission overwrite that is to be deleted's snowflake id
        - parameter on: The channel that we are deleting on
        - parameter callback: An optional callback indicating whether the permission was deleted.
    */
    func deleteChannelPermission(_ overwriteId: String, on channelId: String, callback: ((Bool) -> ())?)

    /**
        Deletes a single message

        - parameter messageId: The message that is to be deleted's snowflake id
        - parameter on: The channel that we are deleting on
        - parameter callback: An optional callback indicating whether the message was deleted.
    */
    func deleteMessage(_ messageId: String, on channelId: String, callback: ((Bool) -> ())?)

    /**
        Unpins a message.

        - parameter messageId: The message that is to be unpinned's snowflake id
        - parameter on: The channel that we are unpinning on
        - parameter callback: An optional callback indicating whether the message was unpinned.
    */
    func deletePinnedMessage(_ messageId: String, on channelId: String, callback: ((Bool) -> ())?)

    /**
        Gets the specified channel.

        - parameter channelId: The snowflake id of the channel
        - parameter callback: The callback function containing an optional `DiscordGuildChannel`
    */
    func getChannel(_ channelId: String, callback: @escaping (DiscordGuildChannel?) -> ())

    /**
        Edits a message

        - parameter messageId: The message that is to be edited's snowflake id
        - parameter on: The channel that we are editing on
        - parameter content: The new content of the message
        - parameter callback: An optional callback containing the edited message, if successful.
    */
    func editMessage(_ messageId: String, on channelId: String, content: String, callback: ((DiscordMessage?) -> ())?)

    /**
        Edits the specified permission overwrite.

        - parameter permissionOverwrite: The new DiscordPermissionOverwrite
        - parameter on: The channel that we are editing on
        - parameter callback: An optional callback indicating whether the edit was successful.
    */
    func editChannelPermission(_ permissionOverwrite: DiscordPermissionOverwrite, on channelId: String,
                               callback: ((Bool) -> ())?)

    /**
        Gets the invites for a channel.

        - parameter for: The channel that we are getting on
        - parameter callback: The callback function, taking an array of `DiscordInvite`
    */
    func getInvites(for channelId: String, callback: @escaping ([DiscordInvite]) -> ())

    /**
        Gets a group of messages according to the specified options.

        - parameter for: The channel that we are getting on
        - parameter options: An array of `DiscordEndpointOptions.GetMessage` options
        - parameter callback: The callback function, taking an array of `DiscordMessages`
    */
    func getMessages(for channel: String, options: [DiscordEndpointOptions.GetMessage],
                     callback: @escaping ([DiscordMessage]) -> ())

    /**
        Modifies the specified channel.

        - parameter channelId: The snowflake id of the channel
        - parameter options: An array of `DiscordEndpointOptions.ModifyChannel` options
        - parameter callback: An optional callback containing the edited guild channel, if successful.
    */
    func modifyChannel(_ channelId: String, options: [DiscordEndpointOptions.ModifyChannel],
                       callback: ((DiscordGuildChannel?) -> ())?)

    /**
        Gets the pinned messages for a channel.

        - parameter for: The channel that we are getting the pinned messages for
        - parameter callback: The callback function, taking an array of `DiscordMessages`
    */
    func getPinnedMessages(for channelId: String, callback: @escaping ([DiscordMessage]) -> ())

    /**
        Sends a message with an optional file and embed to the specified channel.

        Sending just a message:

        ```swift
        client.sendMessage("This is a DiscordMessage", to: channelId, callback: nil)
        ```

        Sending a message with an embed:

        ```swift
        client.sendMessage(DiscordMessage(content: "This message also comes with an embed", embeds: [embed]),
                           to: channelId, callback: nil)
        ```

        Sending a fully loaded message:

         ```swift
        client.sendMessage(DiscordMessage(content: "This message has it all", embeds: [embed],
                                          files: [file]),
                           to: channelId, callback: nil)
        ```

        - parameter message: The message to send.
        - parameter to: The snowflake id of the channel to send to.
        - parameter callback: An optional callback containing the message, if successful.
    */
    func sendMessage(_ message: DiscordMessage, to channelId: String, callback: ((DiscordMessage?) -> ())?)

    /**
        Triggers typing on the specified channel.

        - parameter on: The snowflake id of the channel to send to
        - parameter callback: An optional callback indicating whether typing was triggered.
    */
    func triggerTyping(on channelId: String, callback: ((Bool) -> ())?)

    // MARK: Guilds

    /**
        Adds a role to a guild member.

        - parameter roleId: The id of the role to add.
        - parameter to: The id of the member to add this role to.
        - parameter on: The id of the guild this member is on.
        - parameter with: The token to authenticate to Discord with.
        - parameter callback: An optional callback indicating whether the role was added successfully.
    */
    func addGuildMemberRole(_ roleId: String, to userId: String, on guildId: String, callback: ((Bool) -> ())?)

    /**
        Creates a guild channel.

        - parameter guildId: The snowflake id of the guild
        - parameter options: An array of `DiscordEndpointOptions.GuildCreateChannel` options
        - parameter callback: An optional callback containing the new channel, if successful.
    */
    func createGuildChannel(on guildId: String, options: [DiscordEndpointOptions.GuildCreateChannel],
                            callback: ((DiscordGuildChannel?) -> ())?)

    /**
        Creates a role on a guild.

        - parameter on: The snowflake id of the guild.
        - parameter withOptions: The options for the new role. Optional in the default implementation.
        - parameter callback: The callback function, taking an optional `DiscordRole`.
    */
    func createGuildRole(on guildId: String, withOptions options: [DiscordEndpointOptions.CreateRole],
                         callback: @escaping (DiscordRole?) -> ())

    /**
        Deletes the specified guild.

        - parameter guildId: The snowflake id of the guild
        - parameter callback: An optional callback containing the deleted guild, if successful.
    */
    func deleteGuild(_ guildId: String, callback: ((DiscordGuild?) -> ())?)

    /**
        Gets the bans on a guild.

        - parameter for: The snowflake id of the guild
        - parameter callback: The callback function, taking an array of `DiscordBan`
    */
    func getGuildBans(for guildId: String, callback: @escaping ([DiscordBan]) -> ())

    /**
        Gets the channels on a guild.

        - parameter guildId: The snowflake id of the guild
        - parameter callback: The callback function, taking an array of `DiscordGuildChannel`
    */
    func getGuildChannels(_ guildId: String, callback: @escaping ([DiscordGuildChannel]) -> ())

    /**
        Gets the specified guild member.

        - parameter by: The snowflake id of the member
        - parameter on: The snowflake id of the guild
        - parameter callback: The callback function containing an optional `DiscordGuildMember`
    */
    func getGuildMember(by id: String, on guildId: String, callback: @escaping (DiscordGuildMember?) -> ())

    /**
        Gets the members on a guild.

        - parameter on: The snowflake id of the guild
        - parameter options: An array of `DiscordEndpointOptions.GuildGetMembers` options
        - parameter callback: The callback function, taking an array of `DiscordGuildMember`
    */
    func getGuildMembers(on guildId: String, options: [DiscordEndpointOptions.GuildGetMembers],
                         callback: @escaping ([DiscordGuildMember]) -> ())

    /**
        Gets the roles on a guild.

        - parameter for: The snowflake id of the guild
        - parameter callback: The callback function, taking an array of `DiscordRole`
    */
    func getGuildRoles(for guildId: String, callback: @escaping ([DiscordRole]) -> ())

    /**
        Creates a guild ban.

        - parameter userId: The snowflake id of the user
        - parameter on: The snowflake id of the guild
        - parameter deleteMessageDays: The number of days to delete this user's messages
        - parameter callback: An optional callback indicating whether the ban was successful.
    */
    func guildBan(userId: String, on guildId: String, deleteMessageDays: Int, callback: ((Bool) -> ())?)

    /**
        Modifies the specified guild.

        - parameter guildId: The snowflake id of the guild
        - parameter options: An array of `DiscordEndpointOptions.ModifyGuild` options
        - parameter callback: An optional callback containing the modified guild, if successful.
    */
    func modifyGuild(_ guildId: String, options: [DiscordEndpointOptions.ModifyGuild],
                     callback: ((DiscordGuild?) -> ())?)

    /**
        Modifies the position of a channel.

        - parameter on: The snowflake id of the guild
        - parameter channelPositions: An array of channels that should be reordered. Should contain a dictionary
                                      in the form `["id": channelId, "position": position]`
        - parameter callback: An optional callback containing the modified channels, if successful.
    */
    func modifyGuildChannelPositions(on guildId: String, channelPositions: [[String: Any]],
                                     callback: (([DiscordGuildChannel]) -> ())?)

    /**
        Modifies a guild member.

        - parameter id: The snowflake id of the member.
        - parameter on: The snowflake id of the member to modify.
        - parameter options: The options for this member.
        - parameter callback: The callback function, indicating whether the modify succeeded.
    */
    func modifyGuildMember(_ id: String, on guildId: String, options: [DiscordEndpointOptions.ModifyMember],
                           callback: ((Bool) -> ())?)

    /**
        Edits the specified role.

        - parameter permissionOverwrite: The new DiscordRole
        - parameter on: The guild that we are editing on
        - parameter callback: An optional callback containing the modified role, if successful.
    */
    func modifyGuildRole(_ role: DiscordRole, on guildId: String, callback: ((DiscordRole?) -> ())?)

    /**
        Removes a guild ban.

        - parameter for: The snowflake id of the user
        - parameter on: The snowflake id of the guild
        - parameter callback: An optional callback indicating whether the ban was successfully removed.
    */
    func removeGuildBan(for userId: String, on guildId: String, callback: ((Bool) -> ())?)

    /**
        Removes a role from a guild member.

        - parameter roleId: The id of the role to add.
        - parameter from: The id of the member to add this role to.
        - parameter on: The id of the guild this member is on.
        - parameter with: The token to authenticate to Discord with.
        - parameter callback: An optional callback indicating whether the role was removed successfully.
    */
    func removeGuildMemberRole(_ roleId: String, from userId: String, on guildId: String, callback: ((Bool) -> ())?)

    /**
        Removes a guild role.

        - parameter roleId: The snowflake id of the role
        - parameter on: The snowflake id of the guild
        - parameter callback: An optional callback containing the removed role, if successful.
    */
    func removeGuildRole(_ roleId: String, on guildId: String, callback: ((DiscordRole?) -> ())?)

    // MARK: Webhooks

    /**
        Creates a webhook for a given channel.

        - parameter forChannel: The channel to create the webhook for
        - parameter options: The options for this webhook
        - parameter callback: A callback that returns the webhook created, if successful.
    */
    func createWebhook(forChannel channelId: String, options: [DiscordEndpointOptions.WebhookOption],
                       callback: @escaping (DiscordWebhook?) -> ())

    /**
        Deletes a webhook. The user must be the owner of the webhook.

        - parameter webhookId: The id of the webhook
        - paramter callback: An optional callback function that indicates whether the delete was successful
    */
    func deleteWebhook(_ webhookId: String, callback: ((Bool) -> ())?)

    /**
        Gets the specified webhook.

        - parameter webhookId: The snowflake id of the webhook
        - parameter callback: The callback function containing an optional `DiscordToken`
    */
    func getWebhook(_ webhookId: String, callback: @escaping (DiscordWebhook?) -> ())

    /**
        Gets the webhooks for a specified channel.

        - parameter forChannel: The snowflake id of the channel.
        - parameter callback: The callback function taking an array of `DiscordWebhook`s
    */
    func getWebhooks(forChannel channelId: String, callback: @escaping ([DiscordWebhook]) -> ())

    /**
        Gets the webhooks for a specified guild.

        - parameter forGuild: The snowflake id of the guild.
        - parameter callback: The callback function taking an array of `DiscordWebhook`s
    */
    func getWebhooks(forGuild guildId: String, callback: @escaping ([DiscordWebhook]) -> ())

    /**
        Modifies a webhook.

        - parameter webhookId: The webhook to modify
        - parameter options: The options for this webhook
        - parameter callback: A callback that returns the updated webhook, if successful.
    */
    func modifyWebhook(_ webhookId: String, options: [DiscordEndpointOptions.WebhookOption],
                       callback: @escaping (DiscordWebhook?) -> ())

    // MARK: Invites

    /**
        Accepts an invite.

        - parameter invite: The invite code to accept
        - parameter callback: An optional callback containing the accepted invite, if successful
    */
    func acceptInvite(_ invite: String, callback: ((DiscordInvite?) -> ())?)

    /**
        Deletes an invite.

        - parameter invite: The invite code to delete
        - parameter callback: An optional callback containing the deleted invite, if successful
    */
    func deleteInvite(_ invite: String, callback: ((DiscordInvite?) -> ())?)

    /**
        Gets an invite.

        - parameter invite: The invite code to accept
        - parameter callback: The callback function, takes an optional `DiscordInvite`
    */
    func getInvite(_ invite: String, callback: @escaping (DiscordInvite?) -> ())

    // MARK: Users

    /**
        Creates a direct message channel with a user.

        - parameter with: The user that the channel will be opened with's snowflake id
        - parameter user: Our snowflake id
        - parameter callback: The callback function. Takes an optional `DiscordDMChannel`
    */
    func createDM(with: String, callback: @escaping (DiscordDMChannel?) -> ())

    /**
        Gets the direct message channels for a user.

        - parameter user: Our snowflake id
        - parameter callback: The callback function, taking a dictionary of `DiscordDMChannel` associated by
                              the recipient's id
    */
    func getDMs(callback: @escaping ([String: DiscordDMChannel]) -> ())

    /**
        Gets guilds the user is in.

        - parameter user: Our snowflake id
        - parameter callback: The callback function, taking a dictionary of `DiscordUserGuild` associated by guild id
    */
    func getGuilds(callback: @escaping ([String: DiscordUserGuild]) -> ())

    // MARK: Misc

    /**
        Creates a url that can be used to authorize a bot.

        - parameter with: An array of `DiscordPermission` that this bot should have
    */
    func getBotURL(with permissions: [DiscordPermission]) -> URL?
}

public extension DiscordEndpointConsumer {
    /// Default implementation
    public func acceptInvite(_ invite: String, callback: ((DiscordInvite?) -> ())? = nil) {
        DiscordEndpoint.acceptInvite(invite, with: token, callback: callback)
    }

    /// Default implementation
    public func addPinnedMessage(_ messageId: String, on channelId: String, callback: ((Bool) -> ())? = nil) {
        DiscordEndpoint.addPinnedMessage(messageId, on: channelId, with: token, callback: callback)
    }

    /// Default implementation
    public func addGuildMemberRole(_ roleId: String, to userId: String, on guildId: String,
                                   callback: ((Bool) -> ())?) {
        DiscordEndpoint.addGuildMemberRole(roleId, to: userId, on: guildId, with: token, callback: callback)
    }

    /// Default implementation
    public func bulkDeleteMessages(_ messages: [String], on channelId: String, callback: ((Bool) -> ())? = nil) {
        DiscordEndpoint.bulkDeleteMessages(messages, on: channelId, with: token, callback: callback)
    }

    /// Default implementation
    public func createDM(with: String, callback: @escaping (DiscordDMChannel?) -> ()) {
        DiscordEndpoint.createDM(with: with, user: user!.id, with: token, callback: callback)
    }

    /// Default implementation
    public func createInvite(for channelId: String, options: [DiscordEndpointOptions.CreateInvite],
                             callback: @escaping (DiscordInvite?) -> ()) {
        DiscordEndpoint.createInvite(for: channelId, options: options, with: token, callback: callback)
    }

    /// Default implementation
    public func createGuildChannel(on guildId: String, options: [DiscordEndpointOptions.GuildCreateChannel],
                                   callback: ((DiscordGuildChannel?) -> ())? = nil) {
        DiscordEndpoint.createGuildChannel(guildId, options: options, with: token, callback: callback)
    }

    /// Default implementation
    public func createGuildRole(on guildId: String, withOptions options: [DiscordEndpointOptions.CreateRole] = [],
                                callback: @escaping (DiscordRole?) -> ()) {
        DiscordEndpoint.createGuildRole(on: guildId, withOptions: options, with: token, callback: callback)
    }

    /// Default implementation
    public func createWebhook(forChannel channelId: String, options: [DiscordEndpointOptions.WebhookOption],
                              callback: @escaping (DiscordWebhook?) -> () = {_ in }) {
        DiscordEndpoint.createWebhook(forChannel: channelId, with: token, options: options, callback: callback)
    }

    /// Default implementation
    public func deleteChannel(_ channelId: String, callback: ((Bool) -> ())? = nil) {
        DiscordEndpoint.deleteChannel(channelId, with: token, callback: callback)
    }

    /// Default implementation
    public func deleteChannelPermission(_ overwriteId: String, on channelId: String, callback: ((Bool) -> ())? = nil) {
        DiscordEndpoint.deleteChannelPermission(overwriteId, on: channelId, with: token, callback: callback)
    }

    /// Default implementation
    public func deleteGuild(_ guildId: String, callback: ((DiscordGuild?) -> ())? = nil) {
        DiscordEndpoint.deleteGuild(guildId, with: token, callback: callback)
    }

    /// Default implementation
    public func deleteInvite(_ invite: String, callback: ((DiscordInvite?) -> ())? = nil) {
        DiscordEndpoint.deleteInvite(invite, with: token, callback: callback)
    }

    /// Default implementation
    public func deleteMessage(_ messageId: String, on channelId: String, callback: ((Bool) -> ())? = nil) {
        DiscordEndpoint.deleteMessage(messageId, on: channelId, with: token, callback: callback)
    }

    /// Default implementation
    public func deletePinnedMessage(_ messageId: String, on channelId: String, callback: ((Bool) -> ())? = nil) {
        DiscordEndpoint.deletePinnedMessage(messageId, on: channelId, with: token, callback: callback)
    }

    /// Default implementation
    public func deleteWebhook(_ webhookId: String, callback: ((Bool) -> ())? = nil) {
        DiscordEndpoint.deleteWebhook(webhookId, with: token, callback: callback)
    }

    /// Default implementation
    public func editMessage(_ messageId: String, on channelId: String, content: String,
                            callback: ((DiscordMessage?) -> ())? = nil) {
        DiscordEndpoint.editMessage(messageId, on: channelId, content: content, with: token, callback: callback)
    }

    /// Default implementation
    public func editChannelPermission(_ permissionOverwrite: DiscordPermissionOverwrite, on channelId: String,
                                      callback: ((Bool) -> ())? = nil) {
        DiscordEndpoint.editChannelPermission(permissionOverwrite, on: channelId, with: token, callback: callback)
    }

    /// Default implementation
    public func getChannel(_ channelId: String, callback: @escaping (DiscordGuildChannel?) -> ()) {
        DiscordEndpoint.getChannel(channelId, with: token, callback: callback)
    }

    /// Default implementation
    public func getBotURL(with permissions: [DiscordPermission]) -> URL? {
        guard let user = self.user else { return nil }

        return DiscordOAuthEndpoint.createBotAddURL(for: user, with: permissions)
    }

    /// Default implementation
    public func getDMs(callback: @escaping ([String: DiscordDMChannel]) -> ()) {
        DiscordEndpoint.getDMs(user: user!.id, with: token, callback: callback)
    }

    /// Default implementation
    public func getGuildBans(for guildId: String, callback: @escaping ([DiscordBan]) -> ()) {
        DiscordEndpoint.getGuildBans(for: guildId, with: token, callback: callback)
    }

    /// Default implementation
    public func getGuildChannels(_ guildId: String, callback: @escaping ([DiscordGuildChannel]) -> ()) {
        DiscordEndpoint.getGuildChannels(guildId, with: token, callback: callback)
    }

    /// Default implementation
    public func getGuildMember(by id: String, on guildId: String, callback: @escaping (DiscordGuildMember?) -> ()) {
        DiscordEndpoint.getGuildMember(by: id, on: guildId, with: token, callback: callback)
    }

    /// Default implementation
    public func getGuildMembers(on guildId: String, options: [DiscordEndpointOptions.GuildGetMembers],
                                callback: @escaping ([DiscordGuildMember]) -> ()) {
        DiscordEndpoint.getGuildMembers(on: guildId, options: options, with: token, callback: callback)
    }

    /// Default implementation
    public func getGuilds(callback: @escaping ([String: DiscordUserGuild]) -> ()) {
        DiscordEndpoint.getGuilds(user: user!.id, with: token, callback: callback)
    }

    /// Default implementation
    public func getGuildRoles(for guildId: String, callback: @escaping ([DiscordRole]) -> ()) {
        DiscordEndpoint.getGuildRoles(for: guildId, with: token, callback: callback)
    }

    /// Default implementation
    public func getInvite(_ invite: String, callback: @escaping (DiscordInvite?) -> ()) {
        DiscordEndpoint.getInvite(invite, with: token, callback: callback)
    }

    /// Default implementation
    public func getInvites(for channelId: String, callback: @escaping ([DiscordInvite]) -> ()) {
        return DiscordEndpoint.getInvites(for: channelId, with: token, callback: callback)
    }

    /// Default implementation
    public func getMessages(for channelId: String, options: [DiscordEndpointOptions.GetMessage] = [],
                            callback: @escaping ([DiscordMessage]) -> ()) {
        DiscordEndpoint.getMessages(for: channelId, with: token, options: options, callback: callback)
    }

    /// Default implementation
    public func getWebhook(_ webhookId: String, callback: @escaping (DiscordWebhook?) -> ()) {
        DiscordEndpoint.getWebhook(webhookId, with: token, callback: callback)
    }

    /// Default implementation
    public func getWebhooks(forChannel channelId: String, callback: @escaping ([DiscordWebhook]) -> ()) {
        DiscordEndpoint.getWebhooks(forChannel: channelId, with: token, callback: callback)
    }

    /// Default implementation
    public func getWebhooks(forGuild guildId: String, callback: @escaping ([DiscordWebhook]) -> ()) {
        DiscordEndpoint.getWebhooks(forGuild: guildId, with: token, callback: callback)
    }

    /// Default implementation
    public func guildBan(userId: String, on guildId: String, deleteMessageDays: Int = 7,
                         callback: ((Bool) -> ())? = nil) {
        DiscordEndpoint.guildBan(userId: userId, on: guildId, deleteMessageDays: deleteMessageDays,
            with: token, callback: callback)
    }

    /// Default implementation
    public func getPinnedMessages(for channelId: String, callback: @escaping ([DiscordMessage]) -> ()) {
        DiscordEndpoint.getPinnedMessages(for: channelId, with: token, callback: callback)
    }

    /// Default implementation
    public func modifyChannel(_ channelId: String, options: [DiscordEndpointOptions.ModifyChannel],
                              callback: ((DiscordGuildChannel?) -> ())? = nil) {
        DiscordEndpoint.modifyChannel(channelId, options: options, with: token, callback: callback)
    }

    /// Default implementation
    public func modifyGuild(_ guildId: String, options: [DiscordEndpointOptions.ModifyGuild],
                            callback: ((DiscordGuild?) -> ())? = nil) {
        DiscordEndpoint.modifyGuild(guildId, options: options, with: token, callback: callback)
    }

    /// Default implementation
    public func modifyGuildChannelPositions(on guildId: String, channelPositions: [[String: Any]],
                                            callback: (([DiscordGuildChannel]) -> ())? = nil) {
        DiscordEndpoint.modifyGuildChannelPositions(on: guildId, channelPositions: channelPositions,
            with: token, callback: callback)
    }

    /// Default implementation
    func modifyGuildMember(_ id: String, on guildId: String, options: [DiscordEndpointOptions.ModifyMember],
                           callback: ((Bool) -> ())? = nil) {
        DiscordEndpoint.modifyGuildMember(id, on: guildId, options: options, with: token, callback: callback)
    }

    /// Default implementation
    public func modifyGuildRole(_ role: DiscordRole, on guildId: String, callback: ((DiscordRole?) -> ())? = nil) {
        DiscordEndpoint.modifyGuildRole(role, on: guildId, with: token, callback: callback)
    }

    /// Default implementation
    public func modifyWebhook(_ webhookId: String, options: [DiscordEndpointOptions.WebhookOption],
            callback: @escaping (DiscordWebhook?) -> () = {_ in }) {
        DiscordEndpoint.modifyWebhook(webhookId, with: token, options: options, callback: callback)
    }

    /// Default implementation
    public func removeGuildBan(for userId: String, on guildId: String, callback: ((Bool) -> ())? = nil) {
        DiscordEndpoint.removeGuildBan(for: userId, on: guildId, with: token, callback: callback)
    }

    /// Default implementation.
    public func removeGuildMemberRole(_ roleId: String, from userId: String, on guildId: String,
                                      callback: ((Bool) -> ())?) {
        DiscordEndpoint.removeGuildMemberRole(roleId, from: userId, on: guildId, with: token, callback: callback)
    }

    /// Default implementation
    public func removeGuildRole(_ roleId: String, on guildId: String, callback: ((DiscordRole?) -> ())? = nil) {
        DiscordEndpoint.removeGuildRole(roleId, on: guildId, with: token, callback: callback)
    }

    /// Default implementation.
    public func sendMessage(_ message: DiscordMessage, to channelId: String,
                            callback: ((DiscordMessage?) -> ())? = nil) {
        DiscordEndpoint.sendMessage(message, with: token, to: channelId, callback: callback)
    }

    /// Default implementation
    public func triggerTyping(on channelId: String, callback: ((Bool) -> ())? = nil) {
        DiscordEndpoint.triggerTyping(on: channelId, with: token, callback: callback)
    }
}
