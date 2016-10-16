public enum DiscordPermission : Int {
	case none
	case createInstantInvite = 0x00000001
	case kickMembers = 0x00000002
	case banMembers = 0x00000004
	case administrator = 0x00000008
	case manageChannels = 0x00000010
	case manageGuild = 0x00000020
	case readMessages = 0x00000400
	case sendMessages = 0x00000800
	case sendTTSMessages = 0x00001000
	case manageMessages = 0x00002000
	case embedLinks = 0x00004000
	case attachFiles = 0x00008000
	case readMessageHistory = 0x00010000
	case mentionEveryone = 0x00020000
	case useExternalEmojis = 0x00040000
	case connect = 0x00100000
	case speak = 0x00200000
	case muteMembers = 0x00400000
	case deafenMembers = 0x00800000
	case moveMembers = 0x01000000
	case useVAD = 0x02000000
	case changeNickname = 0x04000000
	case manageNicknames = 0x08000000
	case manageRoles = 0x10000000
}

public func |(lhs: DiscordPermission, rhs: DiscordPermission) -> Int {
	return lhs.rawValue | rhs.rawValue
}

public func &(lhs: DiscordPermission, rhs: DiscordPermission) -> Int {
	return lhs.rawValue & rhs.rawValue
}

public func |(lhs: Int, rhs: DiscordPermission) -> Int {
	return lhs | rhs.rawValue
}

public func &(lhs: Int, rhs: DiscordPermission) -> Int {
	return lhs & rhs.rawValue
}

public func |=(lhs: inout Int, rhs: DiscordPermission) {
	lhs |= rhs.rawValue
}

public func &=(lhs: inout Int, rhs: DiscordPermission) {
	lhs &= rhs.rawValue
}

public enum DiscordPermissionOverwriteType : String {
	case role = "role"
	case member = "member"
}

public struct DiscordPermissionOverwrite {
	public let id: String
	public let type: DiscordPermissionOverwriteType

	public var allow: Int // Bit field
	public var deny: Int // Bit field
}

extension DiscordPermissionOverwrite {
	init(permissionOverwriteObject: [String: Any]) {
		let id = permissionOverwriteObject["id"] as? String ?? ""
		let type = DiscordPermissionOverwriteType(rawValue: permissionOverwriteObject["type"] as? String ?? "") ?? .role
		let allow = permissionOverwriteObject["allow"] as? Int ?? -1
		let deny = permissionOverwriteObject["deny"] as? Int ?? -1

		self.init(id: id, type: type, allow: allow, deny: deny)
	}

	static func overwritesFromArray(_ permissionOverwritesArray: [[String: Any]]) -> [String: DiscordPermissionOverwrite] {
		var overwrites = [String: DiscordPermissionOverwrite]()

		for overwriteObject in permissionOverwritesArray {
			let overwrite = DiscordPermissionOverwrite(permissionOverwriteObject: overwriteObject)

			overwrites[overwrite.id] = overwrite
		}

		return overwrites
	}
}
