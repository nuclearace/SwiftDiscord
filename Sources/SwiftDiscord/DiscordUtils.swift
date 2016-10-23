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
