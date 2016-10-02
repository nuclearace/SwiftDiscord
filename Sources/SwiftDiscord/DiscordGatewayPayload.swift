import Foundation

public enum DiscordGatewayPayloadData {
	case object([String: Any])
	case integer(Int)
	case null

	var value: Any {
		switch self {
		case let .object(object):
			return object
		case let .integer(integer):
			return integer
		case .null:
			return NSNull()
		}
	}
}

extension DiscordGatewayPayloadData {
	static func dataFromDictionary(_ data: Any?) -> DiscordGatewayPayloadData? {
		guard let data = data else { return nil }

		switch data {
		case let object as [String: Any]:
			return .object(object)
		case let integer as Int:
			return .integer(integer)
		case is NSNull:
			return .null
		default:
			return nil
		}
	}
}

public struct DiscordGatewayPayload {
	public let code: DiscordGatewayCode
	public let payload: DiscordGatewayPayloadData
	public let sequenceNumber: Int?
	public let name: String?

	public init(code: DiscordGatewayCode, payload: DiscordGatewayPayloadData, sequenceNumber: Int? = nil, 
		name: String? = nil) {
		self.code = code
		self.payload = payload
		self.sequenceNumber = sequenceNumber
		self.name = name
	}

	func createPayloadString() -> String? {
		var payload: [String: Any] = [
			"op": code.rawValue,
			"d": self.payload.value
		]

		if sequenceNumber != nil {
			payload["s"] = sequenceNumber!
		}

		if name != nil {
			payload["t"] = name!
		}

		return encodeJSON(payload)
	}
}

extension DiscordGatewayPayload {
	static func payloadFromString(_ string: String) -> DiscordGatewayPayload? {
		guard let decodedJSON = decodeJSON(string), case let JSON.dictionary(dictionary) = decodedJSON else { 
			return nil 
		}

		guard let op = dictionary["op"] as? Int, let code = DiscordGatewayCode(rawValue: op), 
			let payload = DiscordGatewayPayloadData.dataFromDictionary(dictionary["d"]) else { 
				return nil 
		}
		
		let sequenceNumber = dictionary["s"] as? Int
		let name = dictionary["t"] as? String

		return DiscordGatewayPayload(code: code, payload: payload, sequenceNumber: sequenceNumber, name: name)
	}
}
