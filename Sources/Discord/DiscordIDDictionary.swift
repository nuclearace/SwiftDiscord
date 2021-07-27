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
