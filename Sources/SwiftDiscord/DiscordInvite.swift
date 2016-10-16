// TODO Meta object

public struct DiscordInvite {
    let code: String
    let guild: DiscordInviteGuild
    let channel: DiscordInviteChannel
}

extension DiscordInvite {
    init(inviteObject: [String: Any]) {
        let code = inviteObject["code"] as? String ?? ""
        let guild = DiscordInviteGuild(inviteGuildObject: inviteObject["guild"] as? [String: Any] ?? [:])
        let channel = DiscordInviteChannel(inviteChannelObject: inviteObject["channel"] as? [String: Any] ?? [:])

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
        let id = inviteGuildObject["id"] as? String ?? ""
        let name = inviteGuildObject["name"] as? String ?? ""
        let splashHash = inviteGuildObject["splash_hash"] as? String ?? ""

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
        let id = inviteChannelObject["id"] as? String ?? ""
        let name = inviteChannelObject["name"] as? String ?? ""
        let type = DiscordChannelType(rawValue: inviteChannelObject["type"] as? String ?? "") ?? .text

        self.init(id: id, name: name, type: type)
    }
}
