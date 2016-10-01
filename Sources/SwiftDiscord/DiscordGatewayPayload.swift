public struct DiscordGatewayPayload {
	let code: DiscordGatewayCode
	let payload: [String: Any]
	let sequenceNumber: Int?
	let name: String?

	public init(code: DiscordGatewayCode, payload: [String: Any], sequenceNumber: Int? = nil, name: String? = nil) {
		self.code = code
		self.payload = payload
		self.sequenceNumber = sequenceNumber
		self.name = name
	}

	func createPayloadString() -> String? {
		var payload: [String: Any] = [
			"op": code.rawValue,
			"d": self.payload 
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
			let payload = dictionary["d"] as? [String: Any] else { 
				return nil 
		}
		
		let sequenceNumber = dictionary["s"] as? Int
		let name = dictionary["t"] as? String

		return DiscordGatewayPayload(code: code, payload: payload, sequenceNumber: sequenceNumber, name: name)
	}
}
