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

/// Represents an audit log.
public class DiscordAuditLog {
    // MARK: Properties

    /// List of audit log entries.
    public let auditLogEntries: [DiscordAuditLogEntry]

    /// List of users found in the audit log
    public let users: [DiscordUser]

    /// List of webhooks found in the audit log
    public let webhooks: [DiscordWebhook]

    init(auditLogObject: [String: Any]) {
        auditLogEntries = DiscordAuditLogEntry.entries(fromArray: auditLogObject.get("audit_log_entries", or: []))
        users = DiscordUser.usersFromArray(auditLogObject.get("users", or: []))
        webhooks = DiscordWebhook.webhooksFromArray(auditLogObject.get("webhooks", or: []))
    }
}
