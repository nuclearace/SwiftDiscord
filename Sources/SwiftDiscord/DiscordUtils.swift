import Foundation

enum JSON {
	case array([Any])
	case dictionary([String: Any])
}

func encodeJSON(_ object: Any) -> String? {
	guard let data = try? JSONSerialization.data(withJSONObject: object) else { return nil }

	return String(data: data, encoding: .utf8)
}

func decodeJSON(_ string: String) -> JSON? {
	guard let data = string.data(using: .utf8, allowLossyConversion: false) else { return nil }
	guard let json = try? JSONSerialization.jsonObject(with: data, options: .mutableContainers) else { return nil }

	switch json {
	case let dictionary as [String: Any]:
		return .dictionary(dictionary)
	case let array as [Any]:
		return .array(array)
	default:
		return nil
	}
}
