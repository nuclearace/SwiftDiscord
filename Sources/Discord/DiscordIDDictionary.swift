// The MIT License (MIT)
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

/// An ID-indexed dictionary that serializes to an array
/// while enabling efficiently indexed access to the elements.
public struct DiscordIDDictionary<Value: Identifiable>: ExpressibleByDictionaryLiteral {
    private var backingDictionary: [Value.ID: Value]

    public var keys: Dictionary<Snowflake, Value>.Keys { backingDictionary.keys }
    public var values: Dictionary<Snowflake, Value>.Values { backingDictionary.values }

    public init(_ backingDictionary: [Value.ID: Value]) {
        self.backingDictionary = backingDictionary
    }

    public init(dictionaryLiteral elements: (Snowflake, Value)...) {
        backingDictionary = Dictionary(uniqueKeysWithValues: elements)
    }

    public subscript(key: Snowflake) -> Value? {
        get { backingDictionary[key] }
        set { backingDictionary[key] = newValue }
    }
}

extension DiscordIDDictionary: Codable where Value: Codable, Value.ID: Codable {
    public init(from decoder: Decoder) throws {
        let values = try [Value](from: decoder)
        let keyedValues = values.map { ($0.id, $0) }
        self.init(Dictionary(uniqueKeysWithValues: keyedValues))
    }

    public func encode(to encoder: Encoder) throws {
        try values.encode(to: encoder)
    }
}
