// The MIT License (MIT)
// Copyright (c) 2017 Erik Little

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

/// Represents an audit entry.
public struct DiscordAuditLogEntry {
    // MARK: Properties

    /// The type of this entry.
    public let actionType: DiscordAuditLogActionType

    /// The changes done in this entry.
    public let changes: [DiscordAuditLogChange]

    /// The id of this entry.
    public let id: Snowflake

    // TODO An actual struct for this?
    /// Optional audit entry information for certain action types.
    /// [Structure](https://discord.com/developers/docs/resources/audit-log#audit-log-entry-object-optional-audit-entry-info)
    public let options: [String: Any]

    /// The reason for this entry.
    public let reason: String

    /// The id of the effected entity.
    public let targetId: String

    /// The user's id who caused this entry.
    public let userId: Snowflake

    init(auditEntryObject: [String: Any]) {
        actionType = DiscordAuditLogActionType(rawValue: auditEntryObject.get("action_type", or: -1)) ?? .other
        changes = DiscordAuditLogChange.changes(fromArray: auditEntryObject.get("changes", or: []))
        id = auditEntryObject.getSnowflake()
        options = auditEntryObject.get("options", or: [:])
        reason = auditEntryObject.get("reason", or: "")
        targetId = auditEntryObject.get("target_id", or: "")
        userId = auditEntryObject.getSnowflake(key: "user_id")
    }

    static func entries(fromArray arr: [[String: Any]]) -> [DiscordAuditLogEntry] {
        return arr.map(DiscordAuditLogEntry.init)
    }
}

// TODO Better types for this
/// Represents a change.
public struct DiscordAuditLogChange {
    // MARK: Properties

    /// The key for this change. Determines the types of the values.
    public let key: String

    /// The new value.
    public let newValue: Any

    /// The old value.
    public let oldValue: Any

    init(changeObject: [String: Any]) {
        key = changeObject.get("key", or: "")
        newValue = changeObject["new_value"] ?? ""
        oldValue = changeObject["old_value"] ?? ""
    }

    static func changes(fromArray arr: [[String: Any]]) -> [DiscordAuditLogChange] {
        return arr.map(DiscordAuditLogChange.init)
    }
}

/// The types of audit actions.
public enum DiscordAuditLogActionType : Int {
    // MARK: Cases

    /// Other
    case other = -1

    /// Guild update.
    case guildUpdate = 1

    /// Channel create.
    case channelCreate = 10

    /// Channel update.
    case channelUpdate = 11

    /// Channel delete.
    case channelDelete = 12

    /// Channel overwrite create.
    case channelOverwriteCreate = 13

    /// Channel overwrite update.
    case channelOverwriteUpdate = 14

    /// Channel overwrite delete.
    case channelOverwriteDelete = 15

    /// Member kick.
    case memberKick = 20

    /// Member prune.
    case memberPrune = 21

    /// Member ban add.
    case memberBanAdd = 22

    /// Member ban remove.
    case memberBanRemove = 23

    /// Member update.
    case memberUpdate = 24

    /// Member role update.
    case memberRoleUpdate = 25

    /// Role create.
    case roleCreate = 30

    /// Role update.
    case roleUpdate = 31

    /// Role delete.
    case roleDelete = 32

    /// Invite create.
    case inviteCreate = 40

    /// Invite update.
    case inviteUpdate = 41

    /// Invite delete.
    case inviteDelete = 42

    /// Webhook create.
    case webhookCreate = 50

    /// Webhook update.
    case webhookUpdate = 51

    /// Webhook delete.
    case webhookDelete = 52

    /// Emoji create.
    case emojiCreate = 60

    /// Emoji update.
    case emojiUpdate = 61

    /// Emoji delete.
    case emojiDelete = 62

    /// Message delete.
    case messageDelete = 72
}
