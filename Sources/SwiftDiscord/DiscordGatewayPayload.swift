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
			"op": code.rawCode,
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
	static func payloadFromString(_ string: String, fromGateway: Bool = true) -> DiscordGatewayPayload? {
		guard let decodedJSON = decodeJSON(string), case let JSON.dictionary(dictionary) = decodedJSON else {
			return nil
		}

		guard let op = dictionary["op"] as? Int,
			let payload = DiscordGatewayPayloadData.dataFromDictionary(dictionary["d"]) else {
				return nil
		}

		let code: DiscordGatewayCode

		if fromGateway, let gatewayCode = DiscordNormalGatewayCode(rawValue: op) {
			code = .gateway(gatewayCode)
		} else if let voiceCode = DiscordVoiceGatewayCode(rawValue: op) {
			code = .voice(voiceCode)
		} else {
			return nil
		}

		let sequenceNumber = dictionary["s"] as? Int
		let name = dictionary["t"] as? String

		return DiscordGatewayPayload(code: code, payload: payload, sequenceNumber: sequenceNumber, name: name)
	}
}
