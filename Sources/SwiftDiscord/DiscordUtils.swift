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

typealias JSONArray = [[String: Any]]

#if os(macOS)
/// A typealias for `Process`. Needed because `Process` on Linux is `Task`.
public typealias EncoderProcess = Process
#elseif os(Linux)
/// A typealias for `Task`. Needed because `Task` on macOS is `Process`.
public typealias EncoderProcess = Task

public extension EncoderProcess {
    /// Whether the task is running.
    var isRunning: Bool {
        return running
    }
}
#endif

extension Dictionary {
    func get<T>(_ value: Key, or default: T) -> T {
        return self[value] as? T ?? `default`
    }
}

extension String {
    var snakecase: String {
        var ret = ""

        for index in characters.indices {
            let stringChar = String(self[index])

            if stringChar.uppercased() == stringChar {
                if index != startIndex {
                    ret += "_"
                }

                ret += stringChar.lowercased()
            } else {
                ret += stringChar
            }
        }

        return ret
    }
}

extension URL {
    static let localhost = URL(string: "http://localhost/")!
}

func createMultipartBody(fields: [String: String], file: DiscordFileUpload?) -> (boundary: String, body: Data) {
    let boundary = "Boundary-\(UUID())"
    var body = Data()

    for (field, value) in fields {
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"\(field)\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(value)\r\n".data(using: .utf8)!)
    }

    if let file = file {
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(file.filename)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: \(file.mimeType)\r\n\r\n".data(using: .utf8)!)
        body.append(file.data)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
    }

    return (boundary, body)
}

class DiscordDateFormatter {
    private static let formatter = DiscordDateFormatter()

    private let RFC3339DateFormatter = DateFormatter()

    private init() {
        RFC3339DateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSSZZZZZ"
    }

    static func format(_ string: String) -> Date? {
        return formatter.RFC3339DateFormatter.date(from: string)
    }
}

protocol Lockable {
    var lock: DispatchSemaphore { get }

    func protected(block: () -> ())
}

extension Lockable {
    func protected(block: () -> ()) {
        lock.wait()
        block()
        lock.signal()
    }
}
