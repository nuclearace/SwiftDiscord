import Foundation

func encodeJSON(_ object: Any) -> String? {
	guard let data = try? JSONSerialization.data(withJSONObject: object) else { return nil }

	return String(data: data, encoding: .utf8)
}
