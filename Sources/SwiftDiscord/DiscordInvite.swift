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
    let code: String
    let guild: DiscordInviteGuild
    let channel: DiscordInviteChannel
}

extension DiscordInvite {
    init(inviteObject: [String: Any]) {
        let code = inviteObject.get("code", or: "")
        let guild = DiscordInviteGuild(inviteGuildObject: inviteObject.get("guild", or: [String: Any]()))
        let channel = DiscordInviteChannel(inviteChannelObject: inviteObject.get("channel", or: [String: Any]()))

        self.init(code: code, guild: guild, channel: channel)
    }

    static func invitesFromArray(inviteArray: [[String: Any]]) -> [DiscordInvite] {
        return inviteArray.map(DiscordInvite.init)
    }
}

public struct DiscordInviteGuild {
    let id: String
    let name: String
    let splashHash: String
}

extension DiscordInviteGuild {
    init(inviteGuildObject: [String: Any]) {
        let id = inviteGuildObject.get("id", or: "")
        let name = inviteGuildObject.get("name", or: "")
        let splashHash = inviteGuildObject.get("splash_hash", or: "")

        self.init(id: id, name: name, splashHash: splashHash)
    }
}

public struct DiscordInviteChannel {
    let id: String
    let name: String
    let type: DiscordChannelType
}

extension DiscordInviteChannel {
    init(inviteChannelObject: [String: Any]) {
        let id = inviteChannelObject.get("id", or: "")
        let name = inviteChannelObject.get("name", or: "")
        let type = DiscordChannelType(rawValue: inviteChannelObject.get("type", or: "")) ?? .text

        self.init(id: id, name: name, type: type)
    }
}
