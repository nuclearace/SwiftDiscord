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

import Dispatch
import Foundation

enum Either<L, R> {
    case left(L)
    case right(R)
}

extension Dictionary where Value == Any {
    func get<T>(_ value: Key, or default: T) -> T {
        return self[value] as? T ?? `default`
    }

    func get<T>(_ value: Key, as type: T.Type) -> T? {
        return self[value] as? T
    }
}

extension Dictionary where Key == String, Value == Any {
    func getSnowflake(key: String = "id") -> Snowflake {
        return Snowflake(self[key] as? String) ?? 0
    }
}

struct EncodableNull: Encodable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encodeNil()
    }
}

/// Swift normally doesn't allow `[Encodable]` to be encoded
struct GenericEncodableArray : Encodable {
    let wrapped: [Any]

    init(_ wrapped: [Any]) {
        self.wrapped = wrapped
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        for item in wrapped {
            let superEncoder = container.superEncoder()
            switch item {
            case let array as [Any]:
                try GenericEncodableArray(array).encode(to: superEncoder)
            case let dictionary as [String: Any]:
                try GenericEncodableDictionary(dictionary).encode(to: superEncoder)
            case let item as Encodable:
                try item.encode(to: superEncoder)
            default:
                throw EncodingError.invalidValue(item, .init(codingPath: encoder.codingPath, debugDescription: "Attempted to encode a value that doesn't conform to encodable"))
            }
        }
    }
}

/// Swift normally doesn't allow `[String: Encodable]` to be encoded
struct GenericEncodableDictionary : Encodable {
    let wrapped: [String: Any]

    private struct GenericEncodingKey : CodingKey {
        var stringValue: String
        var intValue: Int? { return nil }

        init(stringValue: String) {
            self.stringValue = stringValue
        }

        init?(intValue: Int) {
            return nil
        }
    }

    init(_ wrapped: [String: Any]) {
        self.wrapped = wrapped
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: GenericEncodingKey.self)
        for (key, value) in wrapped {
            let superEncoder = container.superEncoder(forKey: GenericEncodingKey(stringValue: key))
            switch value {
            case let array as [Any]:
                try GenericEncodableArray(array).encode(to: superEncoder)
            case let dictionary as [String: Any]:
                try GenericEncodableDictionary(dictionary).encode(to: superEncoder)
            case let value as Encodable:
                try value.encode(to: superEncoder)
            default:
                throw EncodingError.invalidValue(value, .init(codingPath: encoder.codingPath, debugDescription: "Attempted to encode a value that doesn't conform to encodable"))
            }
        }
    }
}

extension URL {
    static let localhost = URL(string: "http://localhost/")!
}

func createMultipartBody(encodedJSON: Data, files: [DiscordFileUpload]) -> (boundary: String, body: Data) {
    let boundary = "Boundary-\(UUID())"
    let crlf = "\r\n".data(using: .utf8)!
    var body = Data()

    body.append("--\(boundary)\r\n".data(using: .utf8)!)
    body.append("Content-Disposition: form-data; name=\"payload_json\"\r\n".data(using: .utf8)!)
    body.append("Content-Type: application/json\r\n".data(using: .utf8)!)
    body.append("Content-Length: \(encodedJSON.count)\r\n\r\n".data(using: .utf8)!)
    body.append(encodedJSON)
    body.append(crlf)

    for (index, file) in files.enumerated() {
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\(index)\"; filename=\"\(file.filename)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: \(file.mimeType)\r\n".data(using: .utf8)!)
        body.append("Content-Length: \(file.data.count)\r\n\r\n".data(using: .utf8)!)
        body.append(file.data)
        body.append(crlf)
    }

    body.append("--\(boundary)--\r\n".data(using: .utf8)!)

    return (boundary, body)
}

// Enum for namespacing
enum DiscordDateFormatter {
    static let rfc3339DateFormatter: DateFormatter = { () -> DateFormatter in
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSSZZZZZ"
        formatter.locale = Locale(identifier: "en_US")
        return formatter
    }()

    static func format(_ string: String) -> Date? {
        return DiscordDateFormatter.rfc3339DateFormatter.date(from: string)
    }

    static func string(from date: Date) -> String {
        return DiscordDateFormatter.rfc3339DateFormatter.string(from: date)
    }
}

protocol Lockable {
    var lock: DispatchSemaphore { get }

    func protected(_ block: () -> ())
    func get<T>(_ getter: @autoclosure () -> T) -> T
}

extension Lockable {
    func protected(_ block: () -> ()) {
        lock.wait()
        block()
        lock.signal()
    }

    func get<T>(_ getter: @autoclosure () -> T) -> T {
        defer { lock.signal() }

        lock.wait()

        return getter()
    }
}
