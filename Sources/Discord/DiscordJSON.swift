// The MIT License (MIT)
// Copyright (c) 2016 Erik Little
// Copyright (c) 2021 fwcd

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

enum DiscordJSON {
    static func makeEncoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .formatted(DiscordDateFormatter.rfc3339DateFormatter)
        return encoder
    }

    static func makeDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(DiscordDateFormatter.rfc3339DateFormatter)
        return decoder
    }

    static func decodeResponse<T>(data: Data?, response: HTTPURLResponse?) -> T? where T: Decodable {
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

        do {
            return try makeDecoder().decode(T.self, from: data)
        } catch {
            logger.error("Could not decode JSON: \(error)")
            return nil
        }
    }
}
