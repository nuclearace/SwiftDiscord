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
