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

// TODO Meta object

public struct DiscordInvite {
    public let code: String
    public let guild: DiscordInviteGuild
    public let channel: DiscordInviteChannel

    init(inviteObject: [String: Any]) {
        code = inviteObject.get("code", or: "")
        guild = DiscordInviteGuild(inviteGuildObject: inviteObject.get("guild", or: [String: Any]()))
        channel = DiscordInviteChannel(inviteChannelObject: inviteObject.get("channel", or: [String: Any]()))
    }

    static func invitesFromArray(inviteArray: [[String: Any]]) -> [DiscordInvite] {
        return inviteArray.map(DiscordInvite.init)
    }
}

public struct DiscordInviteGuild {
    public let id: String
    public let name: String
    public let splashHash: String

    init(inviteGuildObject: [String: Any]) {
        id = inviteGuildObject.get("id", or: "")
        name = inviteGuildObject.get("name", or: "")
        splashHash = inviteGuildObject.get("splash_hash", or: "")
    }
}

public struct DiscordInviteChannel {
    public let id: String
    public let name: String
    public let type: DiscordChannelType

    init(inviteChannelObject: [String: Any]) {
        id = inviteChannelObject.get("id", or: "")
        name = inviteChannelObject.get("name", or: "")
        type = DiscordChannelType(rawValue: inviteChannelObject.get("type", or: "")) ?? .text
    }
}
