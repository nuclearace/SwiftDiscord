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
    case object([String: Any])
}

enum JSONError : Error {
    case collectionError // Thrown when elements in the collection are not representable by json
}

protocol JSONRepresentable {
    func jsonValue() throws -> JSONRepresentable
}

protocol JSONAble : JSONRepresentable {
    var json: [String: JSONRepresentable] { get }
}

extension Array : JSONRepresentable { }
extension Dictionary : JSONRepresentable { }
extension Double : JSONRepresentable { }
extension Int : JSONRepresentable { }
extension NSNull : JSONRepresentable { }
extension Optional : JSONRepresentable { }
extension String : JSONRepresentable { }

extension JSONRepresentable {
    func jsonValue() throws -> JSONRepresentable {
        if self is [AnyHashable: Any] {
            guard let dict = self as? [String: JSONRepresentable] else { throw JSONError.collectionError }

            return try dict.reduce([String: Any](), {cur, keyValue in
                var cur = cur

                cur[keyValue.key.snakecase] = try keyValue.value.jsonValue()

                return cur
            })
        } else if self is [Any] {
            guard let array = self as? [JSONRepresentable] else { throw JSONError.collectionError }

            return try array.map({ try $0.jsonValue() })
        } else if let optionalValue = possibleOptionalRepresentation(of: self) {
            return optionalValue
        }

        return self
    }
}

extension JSONAble {
    var json: [String: JSONRepresentable] {
        var json = [String: JSONRepresentable]()

        let mirror = Mirror(reflecting: self)

        for case let (name?, value) in mirror.children {
            if let nested = value as? JSONAble {
                json[name.snakecase] = nested.json
            } else if let sendable = value as? JSONRepresentable {
                do {
                    json[name.snakecase] = try sendable.jsonValue()
                } catch {
                    DefaultDiscordLogger.Logger.error("Couldn't json property %@", type: "JSONAble", args: name)
                }
            }
        }

        return json
    }

    func jsonValue() -> JSONRepresentable {
        return json
    }
}

private func possibleOptionalRepresentation(of something: Any) -> JSONRepresentable? {
    // Workaround for not being able to do
    // `extension Optional: JSONRepresentable where Wrapped: JSONRepresentable`
    let valueMirror = Mirror(reflecting: something)
    guard valueMirror.displayStyle == .optional else { return nil }
    guard valueMirror.children.count == 1 else { return NSNull() } // If no children, this is .none
    // Make sure the wrapped type is representable in json
    guard case let (_, optionalValue as JSONRepresentable) = valueMirror.children.first! else { return nil }

    if let jsonable = optionalValue as? JSONAble {
        return jsonable.json
    }

    return try? optionalValue.jsonValue()
}
