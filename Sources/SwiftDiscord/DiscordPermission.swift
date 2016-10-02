// TODO permissions

public enum DiscordPermission : Int {
	case none
}

public enum DiscordPermissionOverwriteType {
	case role
	case member

	public init?(string: String) {
		switch string {
		case "role":
			self = .role
		case "member":
			self = .member
		default:
			return nil
		}
	}
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
		let type = DiscordPermissionOverwriteType(string: permissionOverwriteObject["type"] as? String ?? "") ?? .role
		let allow = permissionOverwriteObject["allow"] as? Int ?? -1
		let deny = permissionOverwriteObject["deny"] as? Int ?? -1

		self.init(id: id, type: type, allow: allow, deny: deny)
	}

	static func overwritesFromArray(_ permissionOverwritesArray: [[String: Any]]) -> [DiscordPermissionOverwrite] {
		return permissionOverwritesArray.map(DiscordPermissionOverwrite.init)
	}
}
