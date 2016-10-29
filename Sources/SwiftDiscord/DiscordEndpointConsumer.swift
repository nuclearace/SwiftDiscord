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

public protocol DiscordEndpointConsumer : DiscordClientSpec {
    func acceptInvite(_ invite: String)
    func addPinnedMessage(_ messageId: String, on channelId: String)
    func bulkDeleteMessages(_ messages: [String], on channelId: String)
    func createDM(with: String, callback: @escaping (DiscordDMChannel?) -> Void)
    func createInvite(for channelId: String, options: [DiscordEndpointOptions.CreateInvite],
        callback: @escaping (DiscordInvite?) -> Void)
    func createGuildChannel(on guildId: String, options: [DiscordEndpointOptions.GuildCreateChannel])
    func createGuildRole(on guildId: String, callback: @escaping (DiscordRole?) -> Void)
    func deleteChannel(_ channelId: String)
    func deleteChannelPermission(_ overwriteId: String, on channelId: String)
    func deleteGuild(_ guildId: String)
    func deleteMessage(_ messageId: String, on channelId: String)
    func deletePinnedMessage(_ messageId: String, on channelId: String)
    func editMessage(_ messageId: String, on channelId: String, content: String)
    func editChannelPermission(_ permissionOverwrite: DiscordPermissionOverwrite, on channelId: String)
    func getBotURL(with permissions: [DiscordPermission]) -> URL?
    func getDMs(callback: @escaping ([String: DiscordDMChannel]) -> Void)
    func getChannel(_ channelId: String, callback: @escaping (DiscordGuildChannel?) -> Void)
    func getGuildBans(for guildId: String, callback: @escaping ([DiscordUser]) -> Void)
    func getGuildChannels(_ guildId: String, callback: @escaping ([DiscordGuildChannel]) -> Void)
    func getGuildMember(by id: String, on guildId: String, callback: @escaping (DiscordGuildMember?) -> Void)
    func getGuildMembers(on guildId: String, options: [DiscordEndpointOptions.GuildGetMembers],
        callback: @escaping ([DiscordGuildMember]) -> Void)
    func getGuilds(callback: @escaping ([String: DiscordUserGuild]) -> Void)
    func getGuildRoles(for guildId: String, callback: @escaping ([DiscordRole]) -> Void)
    func getInvite(_ invite: String, callback: @escaping (DiscordInvite?) -> Void)
    func getInvites(for channelId: String, callback: @escaping ([DiscordInvite]) -> Void)
    func getMessages(for channel: String, options: [DiscordEndpointOptions.GetMessage],
        callback: @escaping ([DiscordMessage]) -> Void)
    func getPinnedMessages(for channelId: String, callback: @escaping ([DiscordMessage]) -> Void)
    func guildBan(userId: String, on guildId: String, deleteMessageDays: Int)
    func modifyChannel(_ channelId: String, options: [DiscordEndpointOptions.ModifyChannel])
    func modifyGuild(_ guildId: String, options: [DiscordEndpointOptions.ModifyGuild])
    func modifyGuildRole(_ role: DiscordRole, on guildId: String)
    func removeGuildBan(for userId: String, on guildId: String)
    func removeGuildRole(_ roleId: String, on guildId: String)
    func modifyGuildChannelPosition(on guildId: String, channelId: String, position: Int)
    func sendMessage(_ message: String, to channelId: String, tts: Bool)
    func triggerTyping(on channelId: String)
}

public extension DiscordEndpointConsumer {
    public func acceptInvite(_ invite: String) {
        DiscordEndpoint.acceptInvite(invite, with: token, isBot: isBot)
    }

    public func addPinnedMessage(_ messageId: String, on channelId: String) {
        DiscordEndpoint.addPinnedMessage(messageId, on: channelId, with: token, isBot: isBot)
    }

    public func bulkDeleteMessages(_ messages: [String], on channelId: String) {
        DiscordEndpoint.bulkDeleteMessages(messages, on: channelId, with: token, isBot: isBot)
    }

    public func createDM(with: String, callback: @escaping (DiscordDMChannel?) -> Void) {
        DiscordEndpoint.createDM(with: with, user: user!.id, with: token, isBot: isBot, callback: callback)
    }

    public func createInvite(for channelId: String, options: [DiscordEndpointOptions.CreateInvite],
            callback: @escaping (DiscordInvite?) -> Void) {
        DiscordEndpoint.createInvite(for: channelId, options: options, with: token, isBot: isBot, callback: callback)
    }

    public func createGuildChannel(on guildId: String, options: [DiscordEndpointOptions.GuildCreateChannel]) {
        DiscordEndpoint.createGuildChannel(guildId, options: options, with: token, isBot: isBot)
    }

    public func createGuildRole(on guildId: String, callback: @escaping (DiscordRole?) -> Void) {
        DiscordEndpoint.createGuildRole(on: guildId, with: token, isBot: isBot, callback: callback)
    }

    public func deleteChannel(_ channelId: String) {
        DiscordEndpoint.deleteChannel(channelId, with: token, isBot: isBot)
    }

    public func deleteChannelPermission(_ overwriteId: String, on channelId: String) {
        DiscordEndpoint.deleteChannelPermission(overwriteId, on: channelId, with: token, isBot: isBot)
    }

    public func deleteGuild(_ guildId: String) {
        DiscordEndpoint.deleteGuild(guildId, with: token, isBot: isBot)
    }

    public func deleteMessage(_ messageId: String, on channelId: String) {
        DiscordEndpoint.deleteMessage(messageId, on: channelId, with: token, isBot: isBot)
    }

    public func deletePinnedMessage(_ messageId: String, on channelId: String) {
        DiscordEndpoint.deletePinnedMessage(messageId, on: channelId, with: token, isBot: isBot)
    }

    public func editMessage(_ messageId: String, on channelId: String, content: String) {
        DiscordEndpoint.editMessage(messageId, on: channelId, content: content, with: token, isBot: isBot)
    }

    public func editChannelPermission(_ permissionOverwrite: DiscordPermissionOverwrite, on channelId: String) {
        DiscordEndpoint.editChannelPermission(permissionOverwrite, on: channelId, with: token, isBot: isBot)
    }

    public func getChannel(_ channelId: String, callback: @escaping (DiscordGuildChannel?) -> Void) {
        DiscordEndpoint.getChannel(channelId, with: token, isBot: isBot, callback: callback)
    }

    public func getBotURL(with permissions: [DiscordPermission]) -> URL? {
        guard let user = self.user else { return nil }

        return DiscordOAuthEndpoint.createBotAddURL(for: user, with: permissions)
    }

    public func getDMs(callback: @escaping ([String: DiscordDMChannel]) -> Void) {
        DiscordEndpoint.getDMs(user: user!.id, with: token, isBot: isBot, callback: callback)
    }

    public func getGuildBans(for guildId: String, callback: @escaping ([DiscordUser]) -> Void) {
        DiscordEndpoint.getGuildBans(for: guildId, with: token, isBot: isBot, callback: callback)
    }

    public func getGuildChannels(_ guildId: String, callback: @escaping ([DiscordGuildChannel]) -> Void) {
        DiscordEndpoint.getGuildChannels(guildId, with: token, isBot: isBot, callback: callback)
    }

    public func getGuildMember(by id: String, on guildId: String, callback: @escaping (DiscordGuildMember?) -> Void) {
        DiscordEndpoint.getGuildMember(by: id, on: guildId, with: token, isBot: isBot, callback: callback)
    }

    public func getGuildMembers(on guildId: String, options: [DiscordEndpointOptions.GuildGetMembers],
            callback: @escaping ([DiscordGuildMember]) -> Void) {
        DiscordEndpoint.getGuildMembers(on: guildId, options: options, with: token, isBot: isBot, callback: callback)
    }

    public func getGuilds(callback: @escaping ([String: DiscordUserGuild]) -> Void) {
        DiscordEndpoint.getGuilds(user: user!.id, with: token, isBot: isBot, callback: callback)
    }

    public func getGuildRoles(for guildId: String, callback: @escaping ([DiscordRole]) -> Void) {
        DiscordEndpoint.getGuildRoles(for: guildId, with: token, isBot: isBot, callback: callback)
    }

    public func getInvite(_ invite: String, callback: @escaping (DiscordInvite?) -> Void) {
        DiscordEndpoint.getInvite(invite, with: token, isBot: isBot, callback: callback)
    }

    public func getInvites(for channelId: String, callback: @escaping ([DiscordInvite]) -> Void) {
        return DiscordEndpoint.getInvites(for: channelId, with: token, isBot: isBot, callback: callback)
    }

    public func getMessages(for channelId: String, options: [DiscordEndpointOptions.GetMessage] = [],
            callback: @escaping ([DiscordMessage]) -> Void) {
        DiscordEndpoint.getMessages(for: channelId, with: token, options: options, isBot: isBot, callback: callback)
    }

    public func guildBan(userId: String, on guildId: String, deleteMessageDays: Int = 7) {
        DiscordEndpoint.guildBan(userId: userId, on: guildId, deleteMessageDays: deleteMessageDays, with: token,
            isBot: isBot)
    }

    public func getPinnedMessages(for channelId: String, callback: @escaping ([DiscordMessage]) -> Void) {
        DiscordEndpoint.getPinnedMessages(for: channelId, with: token, isBot: isBot, callback: callback)
    }

    public func modifyChannel(_ channelId: String, options: [DiscordEndpointOptions.ModifyChannel]) {
        DiscordEndpoint.modifyChannel(channelId, options: options, with: token, isBot: isBot)
    }

    public func modifyGuild(_ guildId: String, options: [DiscordEndpointOptions.ModifyGuild]) {
        DiscordEndpoint.modifyGuild(guildId, options: options, with: token, isBot: isBot)
    }

    public func modifyGuildChannelPosition(on guildId: String, channelId: String, position: Int) {
        DiscordEndpoint.modifyGuildChannelPosition(on: guildId, channelId: channelId, position: position,
            with: token, isBot: isBot)
    }

    public func modifyGuildRole(_ role: DiscordRole, on guildId: String) {
        DiscordEndpoint.modifyGuildRole(role, on: guildId, with: token, isBot: isBot)
    }

    public func removeGuildBan(for userId: String, on guildId: String) {
        DiscordEndpoint.removeGuildBan(for: userId, on: guildId, with: token, isBot: isBot)
    }

    public func removeGuildRole(_ roleId: String, on guildId: String) {
        DiscordEndpoint.removeGuildRole(roleId, on: guildId, with: token, isBot: isBot)
    }

    public func sendMessage(_ message: String, to channelId: String, tts: Bool = false) {
        guard connected else { return }

        DiscordEndpoint.sendMessage(message, with: token, to: channelId, tts: tts, isBot: isBot)
    }

    public func triggerTyping(on channelId: String) {
        DiscordEndpoint.triggerTyping(on: channelId, with: token, isBot: isBot)
    }
}
