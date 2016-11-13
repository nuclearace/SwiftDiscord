public struct DiscordDMChannel {
    public let id: String
    public let isPrivate = true
    public let recipient: DiscordUser

    public var lastMessageId: String
}

extension DiscordDMChannel {
    init(dmObject: [String: Any]) {
        let recipient = DiscordUser(userObject: dmObject.get("recipient", or: [String: Any]()))
        let id = dmObject.get("id", or: "")
        let lastMessageId = dmObject.get("lastMessageId", or: "")

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
