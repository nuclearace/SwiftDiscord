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

public struct DiscordRole : JSONAble {
	public let id: String

	public var color: Int
	public var hoist: Bool
	public var managed: Bool
	public var mentionable: Bool
	public var name: String
	public var permissions: Int
	public var position: Int
}

extension DiscordRole {
	init(roleObject: [String: Any]) {
		let color = roleObject.get("color", or: 0)
		let hoist = roleObject.get("hoist", or: false)
		let id = roleObject.get("id", or: "")
		let managed = roleObject.get("managed", or: false)
		let mentionable = roleObject.get("mentionable", or: false)
		let name = roleObject.get("name", or: "")
		let permissions = roleObject.get("permissions", or: 0)
		let position = roleObject.get("position", or: 0)

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
