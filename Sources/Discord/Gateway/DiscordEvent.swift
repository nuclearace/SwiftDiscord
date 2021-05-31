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

///
/// An enum that represents the dispatch events Discord sends.
///
/// If one of these events is handled specifically by the client then it will be turned into an event with the form
/// `myEventName`. If it is not handled, then the associated enum string will be the event name.
///
public enum DiscordDispatchEvent : String {
    /// Ready (Handled)
    case ready = "READY"

    /// Resumed (Handled)
    case resumed = "RESUMED"

    // Messaging

    /// Message Create (Handled)
    case messageCreate = "MESSAGE_CREATE"

    /// Message Delete (Not handled)
    case messageDelete = "MESSAGE_DELETE"

    /// Message Delete Bulk (Not handled)
    case messageDeleteBulk = "MESSAGE_DELETE_BULK"

    /// Message Reaction Add (Handled)
    case messageReactionAdd = "MESSAGE_REACTION_ADD"

    /// Message Reaction Remove All (Handled)
    case messageReactionRemoveAll = "MESSAGE_REACTION_REMOVE_ALL"

    /// Message Reaction Remove (Handled)
    case messageReactionRemove = "MESSAGE_REACTION_REMOVE"

    /// Message Update (Not handled)
    case messageUpdate = "MESSAGE_UPDATE"

    // Guilds

    /// Guild Ban Add (Not handled)
    case guildBanAdd = "GUILD_BAN_ADD"

    /// Guild Ban Remove (Not handled)
    case guildBanRemove = "GUILD_BAN_REMOVE"

    /// Guild Create (Handled)
    case guildCreate = "GUILD_CREATE"

    /// GuildDelete (Handled)
    case guildDelete = "GUILD_DELETE"

    /// Guild Emojis Update (Handled)
    case guildEmojisUpdate = "GUILD_EMOJIS_UPDATE"

    /// Guild Integrations Update (Not handled)
    case guildIntegrationsUpdate = "GUILD_INTEGRATIONS_UPDATE"

    /// Guild Member Add (Handled)
    case guildMemberAdd = "GUILD_MEMBER_ADD"

    /// Guild Member Remove (Handled)
    case guildMemberRemove = "GUILD_MEMBER_REMOVE"

    /// Guild Member Update (Handled)
    case guildMemberUpdate = "GUILD_MEMBER_UPDATE"

    /// Guild Members Chunk (Handled)
    case guildMembersChunk = "GUILD_MEMBERS_CHUNK"

    /// Guild Role Create (Handled)
    case guildRoleCreate = "GUILD_ROLE_CREATE"

    /// Guild Role Delete (Handled)
    case guildRoleDelete = "GUILD_ROLE_DELETE"

    /// Guild Role Update (Handled)
    case guildRoleUpdate = "GUILD_ROLE_UPDATE"

    /// Guild Update (Handled)
    case guildUpdate = "GUILD_UPDATE"

    // Channels

    /// Channel Create (Handled)
    case channelCreate = "CHANNEL_CREATE"

    /// Channel Delete (Handled)
    case channelDelete = "CHANNEL_DELETE"

    /// Channel Pins Update (Not Handled)
    case channelPinsUpdate = "CHANNEL_PINS_UPDATE"

    /// Channel Update (Handled)
    case channelUpdate = "CHANNEL_UPDATE"

    // Voice

    /// Voice Server Update (Handled but no event emitted)
    case voiceServerUpdate = "VOICE_SERVER_UPDATE"

    /// Voice State Update (Handled)
    case voiceStateUpdate = "VOICE_STATE_UPDATE"

    /// Presence Update (Handled)
    case presenceUpdate = "PRESENCE_UPDATE"

    /// Typing Start (Not handled)
    case typingStart = "TYPING_START"

    // Webhooks

    /// Webhooks Update (Not handled)
    case webhooksUpdate = "WEBHOOKS_UPDATE"

    // Applications

    case applicationCommandCreate = "APPLICATION_COMMAND_CREATE"

    case applicationCommandUpdate = "APPLICATION_COMMAND_UPDATE"

    // Interactions

    /// Interaction Create (Handled)
    case interactionCreate = "INTERACTION_CREATE"
}
