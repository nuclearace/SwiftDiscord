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

// Ideally I would like this to be an enum with future and real cases, but it seems that because of how the Collection
// protocol is defined, you can't make the get subscripts mutating, thus you can't change the future value into a real
// value during a get and have them saved. This means the for x in dict { } syntax would not remember the evaulated
// values.
// This works around that by changing the storing of the lazy computation/value to be a reference type, so that the
// backing dictionary of DiscordLazyDictionary is not mutating itself, but the lazy values are.
// This also seems to have a lower memory footprint, for some reason.
/// The backing class for DiscordLazyDictionary's lazy values.
public class DiscordLazyValue<V> {
    fileprivate var real: V?

    private var future: (() -> V)!

    /// The value this objects holds. Forces evaluation.
    public var value: V {
        if let real = real {
            return real
        } else {
            real = future()
            future = nil

            return real!
        }
    }

    private init(future: @escaping () -> V) {
        self.future = future
    }

    private init(real: V) {
        self.real = real
        self.future = nil
    }

    /// Creates a DiscordLazyValue whose value hasn't been computed yet.
    public static func lazy(_ future: @escaping () -> V) -> DiscordLazyValue {
        return DiscordLazyValue(future: future)
    }

    /// Creates a DiscordLazyValue whose value has been computed.
    public static func real(_ real: V) -> DiscordLazyValue {
        return DiscordLazyValue(real: real)
    }
}

extension DiscordLazyValue : CustomStringConvertible {
    /// The descripton of the DiscordLazyValue. Does not evaluate if it hasn't been already.
    public var description: String {
        let value: String

        if let real = real {
            value = "\(real)"
        } else {
            value = "future"
        }

        return "DiscordLazyValue<\(V.self)>{ value: \(value) }"
    }
}

/// Used to index into a DiscordLazyDictionary. Holds the index into the backing dictonary
public struct DiscordLazyDictionaryIndex<K: Hashable, V> : Comparable {
    fileprivate let backingIndex: DictionaryIndex<K, DiscordLazyValue<V>>

    public static func <(lhs: DiscordLazyDictionaryIndex, rhs: DiscordLazyDictionaryIndex) -> Bool {
        return lhs.backingIndex < rhs.backingIndex
    }

    public static func ==(lhs: DiscordLazyDictionaryIndex, rhs: DiscordLazyDictionaryIndex) -> Bool {
        return lhs.backingIndex == rhs.backingIndex
    }
}

/** A value-lazy dictionary

 To store a lazy value into the dictionary:

 ```swift
 var dict = [2: 4] as DiscordLazyDictionary

 dict[lazy: 24] = .lazy({ 2343 + 2343 })
 ```
 */
public struct DiscordLazyDictionary<K: Hashable, V> : ExpressibleByDictionaryLiteral, Collection {
    // MARK: Typealiases/Subscripts

    /// The key type.
    public typealias Key = K

    /// The value type.
    public typealias Value = V

    /// The index type.
    public typealias Index = DiscordLazyDictionaryIndex<Key, Value>

    /// The iterator type.
    public typealias Iterator = Dictionary<Key, Value>.Iterator

    /// The subsequence type.
    public typealias SubSequence =  Dictionary<Key, Value>.SubSequence

    // MARK: Properties

    fileprivate var backingDictionary = [K: DiscordLazyValue<V>]()

    /// - returns: The start index
    public var startIndex: Index {
        return DiscordLazyDictionaryIndex<Key, Value>(backingIndex: backingDictionary.startIndex)
    }

    /// - returns: The end index
    public var endIndex: Index {
        return DiscordLazyDictionaryIndex<Key, Value>(backingIndex: backingDictionary.endIndex)
    }

    /// - returns: A Bool indicating whether this dictionary is empty
    public var isEmpty: Bool {
        return backingDictionary.isEmpty
    }

    /// - returns: The number of stored key/value pairs
    public var count: Int {
        return backingDictionary.count
    }

    /// - returns: The first key/value pair stored in the dictionary.
    public var first: (Key, Value)? {
        guard let firstValue = backingDictionary.first else { return nil }

        return (firstValue.key, firstValue.value.value)
    }

    /**
        Used to get/set the value stored at `key`. This will force evaluation if the value hasn't been computed yet.
        Can be used to set an already computed value.

        - returns: An optional containing the value at `key`, or nil if that key is not in the dictionary
    */
    public subscript(key: Key) -> Value? {
        get {
            guard let value = backingDictionary[key] else { return nil }

            return value.value
        }

        set {
            if let value = newValue {
                backingDictionary[key] = .real(value)
            } else {
                backingDictionary[key] = nil
            }
        }
    }

    /**
        Used to get/set the DiscordLazyValue stored at `key`.
        Can be used to set a lazy value.

        - returns: An optional containing the DiscordLazyValue at `key`, or nil if that key is not in the dictionary
    */
    public subscript(lazy key: Key) -> DiscordLazyValue<V>? {
        get {
            return backingDictionary[key]
        }

        set {
            backingDictionary[key] = newValue
        }
    }

    /**
        Used to get the key/value pair stored at `position`.

        - returns: An optional containing the key/value pair at `key`, or nil if that key is not in the dictionary
    */
    public subscript(position: Index) -> Iterator.Element {
        let backingValues = backingDictionary[position.backingIndex]

        return (backingValues.key, backingValues.value.value)
    }

    /**
        - returns: A slice of dictionary with `bounds`
    */
    public subscript(bounds: Range<Index>) -> SubSequence {
        var base = [Key: Value]()
        let backingRange = backingDictionary[bounds.lowerBound.backingIndex...bounds.upperBound.backingIndex]

        for (key, value) in backingRange {
            base[key] = value.value
        }

        return Slice(base: base, bounds: base.startIndex..<base.endIndex)
    }

    // MARK: Initializers

    /**
        ExpressibleByDictionaryLiteral conformance.

        - parameter dictionaryLiteral: Array of key/value pairs.
    */
    public init(dictionaryLiteral elements: (Key, Value)...) {
        backingDictionary = [Key: DiscordLazyValue<Value>]()

        for element in elements {
            backingDictionary[element.0] = .real(element.1)
        }
    }

    // MARK: Methods

    /**
        Creates an iterator for this dictionary. Forces evaulation of all elements.

        - returns: An iterator for this collection.
    */
    public func makeIterator() -> Iterator {
        var dict = [Key: Value]()

        for (key, value) in backingDictionary {
            dict[key] = value.value
        }

        return dict.makeIterator()
    }

    /**
        - parameter after: The index for which we want the successor to

        - returns: The index after the specified index.
    */
    public func index(after i: Index) -> Index {
        return DiscordLazyDictionaryIndex(backingIndex: backingDictionary.index(after: i.backingIndex))
    }

    /**
        - parameter upTo: the end index for this slice

        - returns: A slice of dictionary up to `upTo`
    */
    public func prefix(upTo end: Index) -> SubSequence {
        var base = [Key: Value]()
        let backingPrefix = backingDictionary.prefix(upTo: end.backingIndex)

        for (key, value) in backingPrefix {
            base[key] = value.value
        }

        return Slice(base: base, bounds: base.startIndex..<base.endIndex)
    }

    /**
        - parameter through: the through index for this slice

        - returns: A slice of dictionary through `upTo`
    */
    public func prefix(through position: Index) -> SubSequence {
        var base = [Key: Value]()
        let backingPrefix = backingDictionary.prefix(through: position.backingIndex)

        for (key, value) in backingPrefix {
            base[key] = value.value
        }

        return Slice(base: base, bounds: base.startIndex..<base.endIndex)
    }

    /**
        - parameter forKey: the key for the value being removed

        - returns: an optional containing the value stored at `key`, or nil if key wasn't stored in this dictionary
    */
    public mutating func removeValue(forKey key: Key) -> Value? {
        return backingDictionary.removeValue(forKey: key)?.value
    }

    /**
        - parameter from: the from index for this slice

        - returns: A slice of dictionary from `from`
    */
    public func suffix(from start: Index) -> SubSequence {
        var base = [Key: Value]()
        let backingSuffix = backingDictionary.suffix(from: start.backingIndex)

        for (key, value) in backingSuffix {
            base[key] = value.value
        }

        return Slice(base: base, bounds: base.startIndex..<base.endIndex)
    }
}

extension DiscordLazyDictionary : CustomStringConvertible {
    // MARK: CustomStringConvertible conformance

    /// A description of this dictionary
    public var description: String {
        return "DiscordLazyDictionary<\(Key.self), \(Value.self)>(\(backingDictionary))"
    }
}
