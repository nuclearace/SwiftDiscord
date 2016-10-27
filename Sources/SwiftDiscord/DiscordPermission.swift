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

public enum DiscordPermission : Int {
	case none
	case createInstantInvite = 0x00000001
	case kickMembers = 0x00000002
	case banMembers = 0x00000004
	case administrator = 0x00000008
	case manageChannels = 0x00000010
	case manageGuild = 0x00000020
	case addReactions = 0x00000040
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

	public init(id: String, type: DiscordPermissionOverwriteType, allow: Int, deny: Int) {
		self.id = id
		self.type = type
		self.allow = allow
		self.deny = deny
	}

	var json: [String: Any] {
		return [
			"id": id,
            "allow": allow,
            "deny": deny,
            "type": type.rawValue
        ]
    }
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
