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

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

///
/// Protocol that declares a type will be a consumer of the Discord REST API.
/// All requests through from a consumer should be rate limited.
///
/// This is where a `DiscordClient` gets the methods that interact with the REST API.
///
/// **NOTE**: Callbacks from the default implementations are *NOT* executed on the client's handleQueue. So it is important
/// that if you make modifications to the client inside of a callback, you first dispatch back on the handleQueue.
///
public protocol DiscordEndpointConsumer {
    // MARK: Properties

    /// The rate limiter for this consumer.
    var rateLimiter: DiscordRateLimiterSpec! { get }

    // MARK: Channels

    ///
    /// Adds a pinned message.
    ///
    /// - parameter messageId: The message that is to be pinned's snowflake id
    /// - parameter on: The channel that we are adding on
    /// - parameter callback: An optional callback indicating whether the pinned message was added.
    ///
    func addPinnedMessage(_ messageId: MessageID,
                          on channelId: ChannelID,
                          callback: ((Bool, HTTPURLResponse?) -> ())?)

    ///
    /// Deletes a bunch of messages at once.
    ///
    /// - parameter messages: An array of message snowflake ids that are to be deleted
    /// - parameter on: The channel that we are deleting on
    /// - parameter callback: An optional callback indicating whether the messages were deleted.
    ///
    func bulkDeleteMessages(_ messages: [MessageID],
                            on channelId: ChannelID,
                            callback: ((Bool, HTTPURLResponse?) -> ())?)

    ///
    /// Creates an invite for a channelguild.
    ///
    /// - parameter for: The channel that we are creating for.
    /// - parameter options: The invitation options.
    /// - parameter reason: The reason this invite was created.
    /// - parameter callback: The callback function. Takes an optional `DiscordInvite`
    ///
    func createInvite(for channelId: ChannelID,
                      options: DiscordEndpoint.Options.CreateInvite,
                      reason: String?,
                      callback: @escaping (DiscordInvite?, HTTPURLResponse?) -> ())

    ///
    /// Creates a reaction for the specified message.
    ///
    /// - parameter for: The message that is to be edited's snowflake id
    /// - parameter on: The channel that we are editing on
    /// - parameter emoji: The emoji name
    /// - parameter callback: An optional callback containing the edited message, if successful.
    ///
    func createReaction(for messageId: MessageID,
                        on channelId: ChannelID,
                        emoji: String,
                        callback: ((DiscordMessage?, HTTPURLResponse?) -> ())?)

    ///
    /// Deletes a reaction the current user has made for the specified message.
    ///
    /// - parameter for: The message that is to be edited's snowflake id
    /// - parameter on: The channel that we are editing on
    /// - parameter emoji: The emoji name
    /// - parameter callback: An optional callback containing the edited message, if successful.
    ///
    func deleteOwnReaction(for messageId: MessageID,
                        on channelId: ChannelID,
                        emoji: String,
                        callback: ((Bool, HTTPURLResponse?) -> ())?)
    
    ///
    /// Deletes a reaction another user has made for the specified message.
    ///
    /// - parameter for: The message that is to be edited's snowflake id
    /// - parameter on: The channel that we are editing on
    /// - parameter emoji: The emoji name
    /// - parameter by: The snowflake id of the user
    /// - parameter callback: An optional callback containing the edited message, if successful.
    ///
    func deleteUserReaction(for messageId: MessageID,
                        on channelId: ChannelID,
                        emoji: String,
                        by userId: UserID,
                        callback: ((Bool, HTTPURLResponse?) -> ())?)

    ///
    /// Deletes the specified channel.
    ///
    /// - parameter channelId: The snowflake id of the channel.
    /// - parameter reason: The reason this channel is being deleted.
    /// - parameter callback: An optional callback indicating whether the channel was deleted.
    ///
    func deleteChannel(_ channelId: ChannelID,
                       reason: String?,
                       callback: ((Bool, HTTPURLResponse?) -> ())?)

    ///
    /// Deletes a channel permission
    ///
    /// - parameter overwriteId: The permission overwrite that is to be deleted's snowflake id.
    /// - parameter on: The channel that we are deleting on.
    /// - parameter reason: The reason this overwrite was deleted.
    /// - parameter callback: An optional callback indicating whether the permission was deleted.
    ///
    func deleteChannelPermission(_ overwriteId: OverwriteID,
                                 on channelId: ChannelID,
                                 reason: String?,
                                 callback: ((Bool, HTTPURLResponse?) -> ())?)

    ///
    /// Deletes a single message
    ///
    /// - parameter messageId: The message that is to be deleted's snowflake id
    /// - parameter on: The channel that we are deleting on
    /// - parameter callback: An optional callback indicating whether the message was deleted.
    ///
    func deleteMessage(_ messageId: MessageID,
                       on channelId: ChannelID,
                       callback: ((Bool, HTTPURLResponse?) -> ())?)

    ///
    /// Unpins a message.
    ///
    /// - parameter messageId: The message that is to be unpinned's snowflake id
    /// - parameter on: The channel that we are unpinning on
    /// - parameter callback: An optional callback indicating whether the message was unpinned.
    ///
    func deletePinnedMessage(_ messageId: MessageID,
                             on channelId: ChannelID,
                             callback: ((Bool, HTTPURLResponse?) -> ())?)

    ///
    /// Gets the specified channel.
    ///
    /// - parameter channelId: The snowflake id of the channel
    /// - parameter callback: The callback function containing an optional `DiscordChannel`
    ///
    func getChannel(_ channelId: ChannelID,
                    callback: @escaping (DiscordChannel?, HTTPURLResponse?) -> ())

    ///
    /// Edits a message
    ///
    /// - parameter messageId: The message that is to be edited's snowflake id
    /// - parameter on: The channel that we are editing on
    /// - parameter content: The new content of the message
    /// - parameter callback: An optional callback containing the edited message, if successful.
    ///
    func editMessage(_ messageId: MessageID,
                     on channelId: ChannelID,
                     content: String,
                     callback: ((DiscordMessage?, HTTPURLResponse?) -> ())?)

    ///
    /// Edits the specified permission overwrite.
    ///
    /// - parameter permissionOverwrite: The new DiscordPermissionOverwrite.
    /// - parameter on: The channel that we are editing on.
    /// - parameter reason: The reason this edit was made.
    /// - parameter callback: An optional callback indicating whether the edit was successful.
    ///
    func editChannelPermission(_ permissionOverwrite: DiscordPermissionOverwrite,
                               on channelId: ChannelID,
                               reason: String?,
                               callback: ((Bool, HTTPURLResponse?) -> ())?)

    ///
    /// Gets the invites for a channel.
    ///
    /// - parameter for: The channel that we are getting on
    /// - parameter callback: The callback function, taking an array of `DiscordInvite`
    ///
    func getInvites(for channelId: ChannelID,
                    callback: @escaping ([DiscordInvite], HTTPURLResponse?) -> ())

    ///
    /// Gets a group of messages according to the specified options.
    ///
    /// - parameter for: The channel that we are getting on
    /// - parameter selection: The selection to use get messages with.  A nil value will use Discord's default, which will get the most recent messages in the channel
    /// - parameter limit: The maximum number of messages to fetch.  Should be in the range 1...100.  A nil value will use Discord's default, which is currently 50.
    /// - parameter callback: The callback function, taking an array of `DiscordMessages`
    ///
    func getMessages(for channel: ChannelID,
                     selection: DiscordEndpoint.Options.MessageSelection?,
                     limit: Int?,
                     callback: @escaping ([DiscordMessage], HTTPURLResponse?) -> ())

    ///
    /// Modifies the specified channel.
    ///
    /// - parameter channelId: The snowflake id of the channel.
    /// - parameter options: Properties to be modified
    /// - parameter reason: The reason this modification is being made.
    /// - parameter callback: An optional callback containing the edited guild channel, if successful.
    ///
    func modifyChannel(_ channelId: ChannelID,
                       options: DiscordEndpoint.Options.ModifyChannel,
                       reason: String?,
                       callback: ((DiscordChannel?, HTTPURLResponse?) -> ())?)

    ///
    /// Gets the pinned messages for a channel.
    ///
    /// - parameter for: The channel that we are getting the pinned messages for
    /// - parameter callback: The callback function, taking an array of `DiscordMessages`
    ///
    func getPinnedMessages(for channelId: ChannelID,
                           callback: @escaping ([DiscordMessage], HTTPURLResponse?) -> ())

    ///
    /// Sends a message with an optional file and embed to the specified channel.
    ///
    /// Sending just a message:
    ///
    /// ```swift
    /// client.sendMessage("This is a DiscordMessage", to: channelId, callback: nil)
    /// ```
    ///
    /// Sending a message with an embed:
    ///
    /// ```swift
    /// client.sendMessage(DiscordMessage(content: "This message also comes with an embed", embed: embed),
    ///                    to: channelId, callback: nil)
    /// ```
    ///
    /// Sending a fully loaded message:
    ///
    /// ```swift
    /// client.sendMessage(DiscordMessage(content: "This message has it all", embed: embed, file: file),
    ///                    to: channelId, callback: nil)
    /// ```
    ///
    /// - parameter message: The message to send.
    /// - parameter to: The snowflake id of the channel to send to.
    /// - parameter callback: An optional callback containing the message, if successful.
    ///
    func sendMessage(_ message: DiscordMessage,
                     to channelId: ChannelID,
                     callback: ((DiscordMessage?, HTTPURLResponse?) -> ())?)

    ///
    /// Triggers typing on the specified channel.
    ///
    /// - parameter on: The snowflake id of the channel to send to
    /// - parameter callback: An optional callback indicating whether typing was triggered.
    ///
    func triggerTyping(on channelId: ChannelID,
                       callback: ((Bool, HTTPURLResponse?) -> ())?)

    ///
    /// Creates a new public thread from an existing message.
    ///
    /// - parameter in: The id of the channel to create a thread in
    /// - parameter options: The parameters of the thread to be created
    /// - parameter reason: The reason this thread is being created
    /// - parameter with: The id of the message to start with
    ///
    func startThread(in channelId: ChannelID,
                     with messageId: MessageID,
                     options: DiscordEndpoint.Options.StartThreadWithMessage,
                     reason: String?,
                     callback: ((DiscordChannel?, HTTPURLResponse?) -> ())?)

    ///
    /// Creates a new public thread without an initial message.
    ///
    /// - parameter in: The id of the channel to create a thread in
    /// - parameter options: The parameters of the thread to be created
    /// - parameter reason: The reason this thread is being created
    ///
    func startThread(in channelId: ChannelID,
                     options: DiscordEndpoint.Options.StartThread,
                     reason: String?,
                     callback: ((DiscordChannel?, HTTPURLResponse?) -> ())?)
    
    ///
    /// Adds the current user to a thread.
    ///
    /// - parameter in: The id of the thread
    ///
    func joinThread(in threadId: ChannelID,
                   callback: ((Bool, HTTPURLResponse?) -> ())?)

    ///
    /// Adds a member to a thread.
    ///
    /// - parameter userId: The user to be added
    /// - parameter to: The id of the thread
    ///
    func addThreadMember(_ userId: UserID,
                         to threadId: ChannelID,
                         callback: ((Bool, HTTPURLResponse?) -> ())?)

    ///
    /// Removes the current user from a thread.
    ///
    /// - parameter in: The id of the thread
    ///
    func leaveThread(in threadId: ChannelID,
                     callback: ((Bool, HTTPURLResponse?) -> ())?)

    ///
    /// Removes a member from a thread.
    ///
    /// - parameter userId: The user to be removed
    /// - parameter to: The id of the thread
    ///
    func removeThreadMember(_ userId: UserID,
                            from threadId: ChannelID,
                            callback: ((Bool, HTTPURLResponse?) -> ())?)

    // MARK: Guilds

    ///
    /// Adds a role to a guild member.
    ///
    /// - parameter roleId: The id of the role to add.
    /// - parameter to: The id of the member to add this role to.
    /// - parameter on: The id of the guild this member is on.
    /// - parameter reason: The reason this member is getting this role.
    /// - parameter callback: An optional callback indicating whether the role was added successfully.
    ///
    func addGuildMemberRole(_ roleId: RoleID,
                            to userId: UserID,
                            on guildId: GuildID,
                            reason: String?,
                            callback: ((Bool, HTTPURLResponse?) -> ())?)

    ///
    /// Creates a guild channel.
    ///
    /// - parameter guildId: The snowflake id of the guild.
    /// - parameter options: The options for the new channel
    /// - parameter reason: The reason this channel is being created.
    /// - parameter callback: An optional callback containing the new channel, if successful.
    ///
    func createGuildChannel(on guildId: GuildID,
                            options: DiscordEndpoint.Options.GuildCreateChannel,
                            reason: String?,
                            callback: ((DiscordChannel?, HTTPURLResponse?) -> ())?)

    ///
    /// Creates a role on a guild.
    ///
    /// - parameter on: The snowflake id of the guild.
    /// - parameter withOptions: The options for the new role. Optional in the default implementation.
    /// - parameter reason: The reason this role is being created.
    /// - parameter callback: The callback function, taking an optional `DiscordRole`.
    ///
    func createGuildRole(on guildId: GuildID,
                         withOptions options: [DiscordEndpoint.Options.CreateRole],
                         reason: String?,
                         callback: @escaping (DiscordRole?, HTTPURLResponse?) -> ())

    ///
    /// Deletes the specified guild.
    ///
    /// - parameter guildId: The snowflake id of the guild
    /// - parameter callback: An optional callback containing the deleted guild, if successful.
    ///
    func deleteGuild(_ guildId: GuildID,
                     callback: ((DiscordGuild?, HTTPURLResponse?) -> ())?)

    ///
    /// Gets a guild's audit log.
    ///
    /// - parameter guildId: The snowflake id of the guild.
    /// - parameter options: Options for getting the audit log.
    /// - parameter callback: A callback with the audit log.
    ///
    func getGuildAuditLog(for guildId: GuildID,
                          withOptions options: [DiscordEndpoint.Options.AuditLog],
                          callback: @escaping (DiscordAuditLog?, HTTPURLResponse?) -> ())

    ///
    /// Gets the bans on a guild.
    ///
    /// - parameter for: The snowflake id of the guild
    /// - parameter callback: The callback function, taking an array of `DiscordBan`
    ///
    func getGuildBans(for guildId: GuildID,
                      callback: @escaping ([DiscordBan], HTTPURLResponse?) -> ())

    ///
    /// Gets the channels on a guild.
    ///
    /// - parameter guildId: The snowflake id of the guild
    /// - parameter callback: The callback function, taking an array of `DiscordChannel`
    ///
    func getGuildChannels(_ guildId: GuildID,
                          callback: @escaping ([DiscordChannel], HTTPURLResponse?) -> ())

    ///
    /// Gets the specified guild member.
    ///
    /// - parameter by: The snowflake id of the member
    /// - parameter on: The snowflake id of the guild
    /// - parameter callback: The callback function containing an optional `DiscordGuildMember`
    ///
    func getGuildMember(by id: UserID,
                        on guildId: GuildID,
                        callback: @escaping (DiscordGuildMember?, HTTPURLResponse?) -> ())

    ///
    /// Gets the members on a guild.
    ///
    /// - parameter on: The snowflake id of the guild
    /// - parameter options: An array of `DiscordEndpointOptions.GuildGetMembers` options
    /// - parameter callback: The callback function, taking an array of `DiscordGuildMember`
    ///
    func getGuildMembers(on guildId: GuildID,
                         options: [DiscordEndpoint.Options.GuildGetMembers],
                         callback: @escaping ([DiscordGuildMember], HTTPURLResponse?) -> ())

    ///
    /// Gets the roles on a guild.
    ///
    /// - parameter for: The snowflake id of the guild
    /// - parameter callback: The callback function, taking an array of `DiscordRole`
    ///
    func getGuildRoles(for guildId: GuildID,
                       callback: @escaping ([DiscordRole], HTTPURLResponse?) -> ())

    ///
    /// Creates a guild ban.
    ///
    /// - parameter userId: The snowflake id of the user.
    /// - parameter on: The snowflake id of the guild.
    /// - parameter deleteMessageDays: The number of days to delete this user's messages.
    /// - parameter reason: The reason for this ban.
    /// - parameter callback: An optional callback indicating whether the ban was successful.
    ///
    func guildBan(userId: UserID,
                  on guildId: GuildID,
                  deleteMessageDays: Int,
                  reason: String?,
                  callback: ((Bool, HTTPURLResponse?) -> ())?)

    ///
    /// Modifies the specified guild.
    ///
    /// - parameter guildId: The snowflake id of the guild.
    /// - parameter options: Properties to be modified
    /// - parameter reason: The reason for this modification.
    /// - parameter callback: An optional callback containing the modified guild, if successful.
    ///
    func modifyGuild(_ guildId: GuildID,
                     options: DiscordEndpoint.Options.ModifyGuild,
                     reason: String?,
                     callback: ((DiscordGuild?, HTTPURLResponse?) -> ())?)

    ///
    /// Modifies the position of a channel.
    ///
    /// - parameter on: The snowflake id of the guild
    /// - parameter channelPositions: An array of channels that should be reordered. Should contain a dictionary
    /// in the form `["id": channelId, "position": position]`
    /// - parameter callback: An optional callback containing the modified channels, if successful.
    ///
    func modifyGuildChannelPositions(on guildId: GuildID,
                                     channelPositions: [[String: Any]],
                                     callback: (([DiscordChannel], HTTPURLResponse?) -> ())?)

    ///
    /// Modifies a guild member.
    ///
    /// - parameter id: The snowflake id of the member.
    /// - parameter on: The snowflake id of the guild for this member.
    /// - parameter options: The options for this member.
    /// - parameter reason: The reason for this change.
    /// - parameter callback: The callback function, indicating whether the modify succeeded.
    ///
    func modifyGuildMember(_ id: UserID,
                           on guildId: GuildID,
                           options: DiscordEndpoint.Options.ModifyMember,
                           reason: String?,
                           callback: ((Bool, HTTPURLResponse?) -> ())?)

    ///
    /// Edits the specified role.
    ///
    /// - parameter permissionOverwrite: The new DiscordRole.
    /// - parameter on: The guild that we are editing on.
    /// - parameter reason: The reason for this edit.
    /// - parameter callback: An optional callback containing the modified role, if successful.
    ///
    func modifyGuildRole(_ role: DiscordRole,
                         on guildId: GuildID,
                         reason: String?,
                         callback: ((DiscordRole?, HTTPURLResponse?) -> ())?)

    ///
    /// Removes a guild ban.
    ///
    /// - parameter for: The snowflake id of the user.
    /// - parameter on: The snowflake id of the guild.
    /// - parameter reason: The reason for this unban.
    /// - parameter callback: An optional callback indicating whether the ban was successfully removed.
    ///
    func removeGuildBan(for userId: UserID,
                        on guildId: GuildID,
                        reason: String?,
                        callback: ((Bool, HTTPURLResponse?) -> ())?)

    ///
    /// Removes a role from a guild member.
    ///
    /// - parameter roleId: The id of the role to add.
    /// - parameter from: The id of the member to add this role to.
    /// - parameter on: The id of the guild this member is on.
    /// - parameter reason: The reason for removing this role.
    /// - parameter callback: An optional callback indicating whether the role was removed successfully.
    ///
    func removeGuildMemberRole(_ roleId: RoleID,
                               from userId: UserID,
                               on guildId: GuildID,
                               reason: String?,
                               callback: ((Bool, HTTPURLResponse?) -> ())?)

    ///
    /// Removes a guild role.
    ///
    /// - parameter roleId: The snowflake id of the role.
    /// - parameter on: The snowflake id of the guild.
    /// - parameter reason: The reason for removing this role.
    /// - parameter callback: An optional callback containing the removed role, if successful.
    ///
    func removeGuildRole(_ roleId: RoleID,
                         on guildId: GuildID,
                         reason: String?,
                         callback: ((DiscordRole?, HTTPURLResponse?) -> ())?)

    // MARK: Webhooks

    ///
    /// Creates a webhook for a given channel.
    ///
    /// - parameter forChannel: The channel to create the webhook for.
    /// - parameter options: The options for this webhook.
    /// - parameter reason: The reason this webhook was created.
    /// - parameter callback: A callback that returns the webhook created, if successful.
    ///
    func createWebhook(forChannel channelId: ChannelID,
                       options: [DiscordEndpoint.Options.WebhookOption],
                       reason: String?,
                       callback: @escaping (DiscordWebhook?, HTTPURLResponse?) -> ())

    ///
    /// Deletes a webhook. The user must be the owner of the webhook.
    ///
    /// - parameter webhookId: The id of the webhook.
    /// - parameter reason: The reason for deleting this webhook.
    /// - paramter callback: An optional callback function that indicates whether the delete was successful.
    ///
    func deleteWebhook(_ webhookId: WebhookID,
                       reason: String?,
                       callback: ((Bool, HTTPURLResponse?) -> ())?)

    ///
    /// Gets the specified webhook.
    ///
    /// - parameter webhookId: The snowflake id of the webhook.
    /// - parameter callback: The callback function containing an optional `DiscordToken`.
    ///
    func getWebhook(_ webhookId: WebhookID,
                    callback: @escaping (DiscordWebhook?, HTTPURLResponse?) -> ())

    ///
    /// Gets the webhooks for a specified channel.
    ///
    /// - parameter forChannel: The snowflake id of the channel.
    /// - parameter callback: The callback function taking an array of `DiscordWebhook`s
    ///
    func getWebhooks(forChannel channelId: ChannelID,
                     callback: @escaping ([DiscordWebhook], HTTPURLResponse?) -> ())

    ///
    /// Gets the webhooks for a specified guild.
    ///
    /// - parameter forGuild: The snowflake id of the guild.
    /// - parameter callback: The callback function taking an array of `DiscordWebhook`s
    ///
    func getWebhooks(forGuild guildId: GuildID,
                     callback: @escaping ([DiscordWebhook], HTTPURLResponse?) -> ())

    ///
    /// Modifies a webhook.
    ///
    /// - parameter webhookId: The webhook to modify.
    /// - parameter options: The options for this webhook.
    /// - parameter reason: The reason for this modification.
    /// - parameter callback: A callback that returns the updated webhook, if successful.
    ///
    func modifyWebhook(_ webhookId: WebhookID,
                       options: [DiscordEndpoint.Options.WebhookOption],
                       reason: String?,
                       callback: @escaping (DiscordWebhook?, HTTPURLResponse?) -> ())

    // MARK: Invites

    ///
    /// Accepts an invite.
    ///
    /// - parameter invite: The invite code to accept
    /// - parameter callback: An optional callback containing the accepted invite, if successful
    ///
    func acceptInvite(_ invite: String,
                      callback: ((DiscordInvite?, HTTPURLResponse?) -> ())?)

    ///
    /// Deletes an invite.
    ///
    /// - parameter invite: The invite code to delete.
    /// - parameter reason: The reason this invite was deleted.
    /// - parameter callback: An optional callback containing the deleted invite, if successful.
    ///
    func deleteInvite(_ invite: String,
                      reason: String?,
                      callback: ((DiscordInvite?, HTTPURLResponse?) -> ())?)

    ///
    /// Gets an invite.
    ///
    /// - parameter invite: The invite code to accept
    /// - parameter callback: The callback function, takes an optional `DiscordInvite`
    ///
    func getInvite(_ invite: String,
                   callback: @escaping (DiscordInvite?, HTTPURLResponse?) -> ())

    // MARK: Users

    ///
    /// Creates a direct message channel with a user.
    ///
    /// - parameter with: The user that the channel will be opened with's snowflake id
    /// - parameter user: Our snowflake id
    /// - parameter callback: The callback function. Takes an optional `DiscordChannel`
    ///
    func createDM(with: UserID,
                  callback: @escaping (DiscordChannel?, HTTPURLResponse?) -> ())

    ///
    /// Gets the direct message channels for a user.
    ///
    /// - parameter user: Our snowflake id
    /// - parameter callback: The callback function, taking the channels
    ///
    func getDMs(callback: @escaping ([DiscordChannel], HTTPURLResponse?) -> ())

    ///
    /// Gets guilds the user is in.
    ///
    /// - parameter user: Our snowflake id
    /// - parameter callback: The callback function, taking the guilds
    ///
    func getGuilds(callback: @escaping ([DiscordGuild], HTTPURLResponse?) -> ())

    // MARK: Applications

    ///
    /// Gets the global slash-commands of a user.
    ///
    /// - parameter callback: The callback function, taking the commands
    ///
    func getApplicationCommands(callback: @escaping ([DiscordApplicationCommand], HTTPURLResponse?) -> ())

    ///
    /// Creates a global slash-command for a user.
    ///
    /// - parameter callback: The callback function, taking a command.
    ///
    func createApplicationCommand(name: String,
                                  description: String,
                                  options: [DiscordApplicationCommandOption]?,
                                  callback: ((DiscordApplicationCommand?, HTTPURLResponse?) -> ())?)

    ///
    /// Edits a global slash-command for a user.
    ///
    /// - parameter callback: The callback function, taking a command.
    ///
    func editApplicationCommand(_ commandId: CommandID,
                                name: String,
                                description: String,
                                options: [DiscordApplicationCommandOption]?,
                                callback: ((DiscordApplicationCommand?, HTTPURLResponse?) -> ())?)

    ///
    /// Deletes a global slash-command for a user.
    ///
    /// - parameter callback: The callback function, taking a command.
    ///
    func deleteApplicationCommand(_ commandId: CommandID,
                                  callback: ((HTTPURLResponse?) -> ())?)

    ///
    /// Gets the guild-specific slash-commands of a user.
    ///
    /// - parameter callback: The callback function, taking a dictionary of commands.
    ///
    func getApplicationCommands(on guildId: GuildID,
                                callback: @escaping ([DiscordApplicationCommand], HTTPURLResponse?) -> ())

    ///
    /// Creates a guild-specific slash-command for a user.
    ///
    /// - parameter callback: The callback function, taking a command.
    ///
    func createApplicationCommand(on guildId: GuildID,
                                  name: String,
                                  description: String,
                                  options: [DiscordApplicationCommandOption]?,
                                  callback: ((DiscordApplicationCommand?, HTTPURLResponse?) -> ())?)

    ///
    /// Edits a guild-specific slash-command for a user.
    ///
    /// - parameter callback: The callback function, taking a command.
    ///
    func editApplicationCommand(_ commandId: CommandID,
                                on guildId: GuildID,
                                name: String,
                                description: String,
                                options: [DiscordApplicationCommandOption]?,
                                callback: ((DiscordApplicationCommand?, HTTPURLResponse?) -> ())?)

    ///
    /// Deletes a guild-specific slash-command for a user.
    ///
    /// - parameter callback: The callback function, taking a command.
    ///
    func deleteApplicationCommand(_ commandId: CommandID,
                                  on guildId: GuildID,
                                  callback: ((HTTPURLResponse?) -> ())?)

    ///
    /// Creates a response to an interaction from the gateway.
    ///
    /// - parameter response: The response
    ///
    func createInteractionResponse(for interactionId: InteractionID,
                                   token: String,
                                   response: DiscordInteractionResponse,
                                   callback: ((HTTPURLResponse?) -> ())?)

    // MARK: Misc

    ///
    /// Creates a url that can be used to authorize a bot.
    ///
    /// - parameter with: An array of `DiscordPermissions` that this bot should have
    ///
    func getBotURL(with permissions: DiscordPermissions) -> URL?
}

public extension DiscordEndpointConsumer where Self: DiscordUserActor {
    /// Default implementation
    func getBotURL(with permissions: DiscordPermissions) -> URL? {
        guard let user = self.user else { return nil }

        return DiscordOAuthEndpoint.createBotAddURL(for: user, with: permissions)
    }
}
