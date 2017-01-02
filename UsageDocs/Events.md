Events
======

These are the events that are emitted by the client, and that handlers can be added for.

System Events
-------------

These are events related to the state of the client.

- System Events
    - `connect`: Emitted when all of a client's shards have connected. After this event the client
        the client is considered "ready"
    - `disconnect`: Emitted after calling the `disconnect` method and all shards have disconnected.
    - `voiceEngine.ready`: Emitted when the voice engine is ready to start playing audio. At a lower level, it is
        emitted every time a new encoder is created.


Discord Events
--------------

These are events that are emitted in response to the client receiving the event from Discord. These are emitted after
the client has already handled the event and any state changes. These events will have data emited with them.

**Note**: These are only events that the client handles. All events from Discord that aren't handled are also emitted.
For the full list of events see [DiscordDispatchEvent][DiscordDispatchEvent].

- Discord Events
    - `channelCreate`: Emitted when a new channel is created. Has a single data item of type
        [DiscordChannel][DiscordChannel], which is the created channel.
    - `channelDelete`: Emitted when a channel is deleted. Has a single data item of type
        [DiscordChannel][DiscordChannel], which is the deleted channel.
    - `channelUpdate`: Emitted when a channel is updated. Has a single data item of type
        [DiscordChannel][DiscordChannel], which is the updated channel.
    - `guildCreate`: Emitted when a guild is created. Has a single data item of type [DiscordGuild][DiscordGuild],
        which is the guild that was created.
    - `guildDelete`: Emitted when a guild is deleted. Has a single data item of type [DiscordGuild][DiscordGuild],
        which is the guild that was deleted.
    - `guildUpdate`: Emitted when a guild is updated. Has a single data item of type [DiscordGuild][DiscordGuild],
        which is the guild that was updated.
    - `guildEmojisUpdate`: Emitted when a guild's emoji are updated. Has two data items, the first is a dictionary of
        [DiscordEmoji][DiscordEmoji] indexed by their id, the second is the id of the guild for the emoji.
    - `guildMemberAdd`: Emitted when a member joins a guild. Has two data items, the first is a
        [DiscordGuildMember][DiscordGuildMember], the second is the id of the guild.
    - `guildMemberRemove`: Emitted when a member leaves a guild. Has two data items, the first is a
        [DiscordGuildMember][DiscordGuildMember], the second is the id of the guild.
    - `guildMemberUpdate`: Emitted when a member is updated. Has two data items, the first is a
        [DiscordGuildMember][DiscordGuildMember], the second is the id of the guild.
    - `guildMembersChunk`: Emitted when a chunk of guild members is received. Has two data items, the first is a
        dictionary of [DiscordGuildMember][DiscordGuildMember] indexed by their id, the second is the id of the guild.
    - `guildRoleCreate`: Emitted when a role is created. Has two data items, the first is a
        [DiscordRole][DiscordRole], the second is the id of the guild.
    - `guildRoleRemove`: Emitted when a Role is deleted. Has two data items, the first is a
        [DiscordRole][DiscordRole], the second is the id of the guild.
    - `guildRoleUpdate`: Emitted when a Role is updated. Has two data items, the first is a
        [DiscordRole][DiscordRole], the second is the id of the guild.
    - `messageCreate`: Emitted when a message is created. Has a single data item, the [DiscordMessage][DiscordMessage]
        that was created.
    - `presenceUpdate`: Emitted when a presence is updated. Has a single data item, the
        [DiscordPresence][DiscordPresence] that was updated.
    - `ready`: Emitted when a shard receives a ready event. Has a single data item, the raw dictionary of the event.
    - `voiceStateUpdate`: Emitted when a voice state changes. Has a single data item, the
        [DiscordVoiceState][DiscordVoiceState] that was updated.


[DiscordChannel]: ./Protocols/DiscordChannel.html
[DiscordGuild]: ./Classes/DiscordGuild.html
[DiscordEmoji]: ./Structs/DiscordEmoji.html
[DiscordDispatchEvent]: ./Enums/DiscordDispatchEvent.html
[DiscordGuildMember]: ./Structs/DiscordGuildMember.html
[DiscordRole]: ./Structs/DiscordRole.html
[DiscordMessage]: ./Structs/DiscordMessage.html
[DiscordPresence]: ./Structs/DiscordPresence.html
[DiscordVoiceState]: ./Structs/DiscordVoiceState.html
