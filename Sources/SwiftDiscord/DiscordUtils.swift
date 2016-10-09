import Foundation

enum JSON {
	case array([Any])
	case dictionary([String: Any])
}

// Why does Apple not expose this?
infix operator &<< : BitwiseShiftPrecedence

public func &<<(lhs: Int, rhs: Int) -> Int {
    let bitsCount = MemoryLayout<Int>.size * 8
    let shiftCount = min(rhs, bitsCount - 1)
    var shiftedValue = 0
    
    for bitIndex in 0..<bitsCount {
        let bit = 1 << bitIndex

        if lhs & bit == bit {
            shiftedValue = shiftedValue | (bit << shiftCount)
        }
    }
    
    return shiftedValue
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

func convertISO8601(string: String) -> Date? {
	if #available(macOS 10.12, iOS 10, *) {
		let formatter = ISO8601DateFormatter()

		formatter.formatOptions = .withFullDate

		return formatter.date(from: string)
	} else {
		let RFC3339DateFormatter = DateFormatter()

		RFC3339DateFormatter.dateFormat = "YYYY-MM-DD'T'HH:mm:ss.SSSSSS+HH:mm"

		return RFC3339DateFormatter.date(from: string)
	}
}
