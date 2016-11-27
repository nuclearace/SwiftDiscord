public struct DiscordDMChannel {
    public let id: String
    public let isPrivate = true
    public let recipient: DiscordUser

    public var lastMessageId: String

    init(dmObject: [String: Any]) {
        recipient = DiscordUser(userObject: dmObject.get("recipient", or: [String: Any]()))
        id = dmObject.get("id", or: "")
        lastMessageId = dmObject.get("lastMessageId", or: "")
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
