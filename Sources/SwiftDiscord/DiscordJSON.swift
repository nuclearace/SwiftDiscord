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
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import Logging

fileprivate let logger = Logger(label: "DiscordJSON")

enum JSON {
    case array([Any])
    case object([String: Any])

    static func encodeJSONData<T: Encodable>(_ object: T) -> Data? {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .formatted(DiscordDateFormatter.rfc3339DateFormatter)
        do {
            return try encoder.encode(object)
        } catch let error as EncodingError {
            logger.error("Failed to encode json \(object): \(error.localizedDescription)")
            return nil
        } catch {
            logger.error("Failed to encode json \(object): \(error)")
            return nil
        }
    }

    static func encodeJSON<T: Encodable>(_ object: T) -> String? {
        return encodeJSONData(object).flatMap({ String(data: $0, encoding: .utf8) })
    }

    static func decodeJSON(_ string: String) -> JSON? {
        guard let data = string.data(using: .utf8, allowLossyConversion: false) else { return nil }
        guard let json = try? JSONSerialization.jsonObject(with: data, options: .mutableContainers) else { return nil }

        switch json {
        case let dictionary as [String: Any]:
            return .object(dictionary)
        case let array as [Any]:
            return .array(array)
        default:
            return nil
        }
    }

    static func jsonFromResponse(data: Data?, response: HTTPURLResponse?) -> JSON? {
        guard let response = response else {
            logger.error("No response from jsonFromResponse")

            return nil
        }

        guard let data = data, let stringData = String(data: data, encoding: .utf8) else {
            logger.error("Not string data? Response code: \(response.statusCode)")

            return nil
        }

        guard response.statusCode != 204 else {
            logger.debug("Response code 204: No content")
            
            return nil
        }

        guard response.statusCode == 200 || response.statusCode == 201 else {
            logger.error("Invalid response code \(response.statusCode)")
            logger.error("Response: \(stringData)")

            return nil
        }

        return JSON.decodeJSON(stringData)
    }
}

typealias JSONArray = [[String: Any]]

enum JSONError : Error {
    case collectionError // Thrown when elements in the collection are not representable by json
}

