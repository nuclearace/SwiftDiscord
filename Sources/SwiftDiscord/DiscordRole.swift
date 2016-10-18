import Foundation

public struct DiscordRole {
	public let id: String

	public var color: Int
	public var hoist: Bool
	public var managed: Bool
	public var mentionable: Bool
	public var name: String
	public var permissions: Int
	public var position: Int

	var json: [String: Any] {
		return [
			"id": id,
			"color": color,
			"hoist": hoist,
			"managed": managed,
			"mentionable": mentionable,
			"name": name,
			"permissions": permissions,
			"position": position
		]
	}
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

		self.init(id: id, color: color, hoist: hoist, managed: managed, mentionable: mentionable, name: name,
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
