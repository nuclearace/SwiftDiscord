public struct DiscordDMChannel {
    public let id: String
    public let isPrivate = true
    public let recipient: DiscordUser

    public var lastMessageId: String
}

extension DiscordDMChannel {
    init(dmObject: [String: Any]) {
        let recipient = DiscordUser(userObject: dmObject["recipient"] as? [String: Any] ?? [:])
        let id = dmObject["id"] as? String ?? ""
        let lastMessageId = dmObject["lastMessageId"] as? String ?? ""

        self.init(id: id, recipient: recipient, lastMessageId: lastMessageId)
    }

    static func DMsfromArray(_ dmArray: [[String: Any]]) -> [String: DiscordDMChannel] {
        var dms = [String: DiscordDMChannel]()

        for dm in dmArray {
            let dmChannel = DiscordDMChannel(dmObject: dm)

            dms[dmChannel.id] = dmChannel
        }

        return dms
    }
}
