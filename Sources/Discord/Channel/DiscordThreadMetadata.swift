// The MIT License (MIT)
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

/// Additional metadata about a thread.
public struct DiscordThreadMetadata: Codable {
    public enum CodingKeys: String, CodingKey {
        case archived
        case autoArchiveDuration = "auto_archive_duration"
        case archiveTimestamp = "archive_timestamp"
        case locked
    }

    /// Whether the thread is archived.
    public var archived: Bool

    /// Duration in minutes, to auto-archive the thread.
    /// Can be set to 60, 1440, 4320, 10080.
    public var autoArchiveDuration: Int

    /// Timestamp when the thread's archive status was
    /// last changed, used for calculating lecent activity.
    public var archiveTimestamp: Date

    /// Whether the thread is locked, i.e. only users with
    /// `MANAGE_THREADS` can unarchive it.
    public var locked: Bool?
}
