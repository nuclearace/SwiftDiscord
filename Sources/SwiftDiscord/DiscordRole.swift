import Foundation

// TODO permissions
public enum DiscordPermission : Int {
	case none
}

public struct DiscordRole {
	let color: Int
	let hoist: Bool
	let id: String
	let managed: Bool
	let mentionable: Bool
	let name: String
	let permissions: Int // Bit field
	let position: Int
}

extension DiscordRole {
	init(roleObject: [String: Any]) {
		let color = roleObject["color"] as? Int ?? -1
		let hoist = roleObject["hoist"] as? Bool ?? false
		let id = roleObject["id"] as? String ?? ""
		let managed = roleObject["managed"] as? Bool ?? false
		let mentionable = roleObject["mentionable"] as? Bool ?? false
		let name = roleObject["name"] as? String ?? ""
		let permissions = roleObject["permissions"] as? Int ?? -1
		let position = roleObject["position"] as? Int ?? -1

		self.init(color: color, hoist: hoist, id: id, managed: managed, mentionable: mentionable, name: name, 
			permissions: permissions, position: position)
	}

	static func rolesFromArray(_ rolesArray: [[String: Any]]) -> [String: DiscordRole] {
		var roles = [String: DiscordRole]()

		for role in rolesArray {
			let role = DiscordRole(roleObject: role)

			roles[role.id] = role
		}

		return roles
	}
}
