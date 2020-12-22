import Foundation

/// Represents a slash-command. The base command model of the
/// application.
public struct DiscordApplicationCommand: Encodable {
    // MARK: Properties

    /// The ID of the command.
    public let id: CommandID

    /// The ID of the parent application.
    public let applicationId: ApplicationID

    /// 3-32 character name
    public let name: String

    /// 1-100 character description
    public let description: String

    /// The parameters for the command
    public let parameters: DiscordApplicationCommandOption
}

public struct DiscordApplicationCommandOption: Encodable {
    /// The expected type
    public let type: DiscordApplicationCommandOptionType

    /// 1-32 character name
    public let name: String

    /// 1-100 character description
    public let description: String

    /// The first required option for the user to complete
    /// Only one option can be default
    public let isDefault: Bool?

    /// If the parameter is required or optional, default is false
    public let isRequired: Bool?

    /// Choices for string and int types for the user to pick from
    public let choices: [DiscordApplicationCommandOptionChoice]?

    /// If the option is a subcommand or subcommand group, these
    /// nested options will be the parameters
    public let options: [DiscordApplicationCommandOption]
}

public struct DiscordApplicationCommandOptionChoice: Encodable {
    /// 1-100 character choice name
    public let name: String

    /// Value of the choice
    public let value: DiscordApplicationCommandOptionChoiceValue
}

public enum DiscordApplicationCommandOptionChoiceValue: Encodable {
    case string(String)
    case int(Int)

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let s):
            try container.encode(s)
        case .int(let i):
            try container.encode(i)
        }
    }
}

public enum DiscordApplicationCommandOptionType: Int, Encodable {
    case subCommand = 1
    case subCommandGroup = 2
    case string = 3
    case integer = 4
    case boolean = 5
    case user = 6
    case channel = 7
    case role = 8

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}

public struct DiscordApplicationCommandInteractionData {
    /// The ID of the invoked command
    public let id: CommandID

    /// The name of the invoked command
    public let name: String

    /// The params + values by the user
    public let options: [DiscordApplicationCommandInteractionDataOption]

    init(dataObject: [String: Any]) {
        id = Snowflake(dataObject["id"] as? String) ?? 0
        name = dataObject.get("name", as: String.self) ?? ""
        options = (dataObject["options"] as? [[String: Any]])?.map(DiscordApplicationCommandInteractionDataOption.init(optionObject:)).compactMap { $0 } ?? []
    }
}

public struct DiscordApplicationCommandInteractionDataOption {
    /// The name of the parameter.
    public let name: String

    /// The value of the pair. Type is the OptionType of the command.
    public let value: Any?

    /// Present if this option is a group or subcommand.
    public let options: [DiscordApplicationCommandInteractionDataOption]?

    init(optionObject: [String: Any]) {
        name = optionObject.get("name", as: String.self) ?? ""
        value = optionObject["value"]
        options = (optionObject["options"] as? [[String: Any]])?.map(DiscordApplicationCommandInteractionDataOption.init(optionObject:)).compactMap { $0 } ?? []
    }
}
