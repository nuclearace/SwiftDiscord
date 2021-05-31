import Foundation

/// Represents a slash-command. The base command model of the
/// application.
public struct DiscordApplicationCommand: Encodable {
    public enum CodingKeys: String, CodingKey {
        case id
        case applicationId = "application_id"
        case name
        case description
        case parameters
    }

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
    public let parameters: [DiscordApplicationCommandOption]

    init(commandObject: [String: Any]) {
        id = Snowflake((commandObject["id"] as? String) ?? "") ?? 0
        applicationId = Snowflake((commandObject["application_id"] as? String) ?? "") ?? 0
        name = (commandObject["name"] as? String) ?? ""
        description = (commandObject["description"] as? String) ?? ""
        parameters = ((commandObject["parameters"] as? [[String: Any]]) ?? []).map(DiscordApplicationCommandOption.init(optionObject:))
    }

    static func commandsFromArray(_ array: [[String: Any]]) -> [DiscordApplicationCommand] {
        return array.map({ DiscordApplicationCommand(commandObject: $0) })
    }
}

public struct DiscordApplicationCommandOption: Encodable {
    public enum CodingKeys: String, CodingKey {
        case type
        case name
        case description
        case isDefault = "default"
        case isRequired = "required"
        case choices
        case options
    }

    /// The expected type
    public let type: DiscordApplicationCommandOptionType?

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
    public let options: [DiscordApplicationCommandOption]?

    public init(
        type: DiscordApplicationCommandOptionType,
        name: String,
        description: String,
        isDefault: Bool? = nil,
        isRequired: Bool? = nil,
        choices: [DiscordApplicationCommandOptionChoice]? = nil,
        options: [DiscordApplicationCommandOption]? = nil
    ) {
        self.type = type
        self.name = name
        self.description = description
        self.isDefault = isDefault
        self.isRequired = isRequired
        self.choices = choices
        self.options = options
    }

    init(optionObject: [String: Any]) {
        type = (optionObject["type"] as? Int).flatMap(DiscordApplicationCommandOptionType.init(rawValue:))
        name = (optionObject["name"] as? String) ?? ""
        description = (optionObject["description"] as? String) ?? ""
        isDefault = (optionObject["default"] as? Bool) ?? false
        isRequired = (optionObject["required"] as? Bool) ?? false
        choices = (optionObject["choices"] as? [[String: Any]]).map { $0.compactMap(DiscordApplicationCommandOptionChoice.init(choiceObject:)) }
        options = (optionObject["options"] as? [[String: Any]]).map { $0.map(DiscordApplicationCommandOption.init(optionObject:)) }
    }
}

public struct DiscordApplicationCommandOptionChoice: Encodable {
    /// 1-100 character choice name
    public let name: String

    /// Value of the choice
    public let value: DiscordApplicationCommandOptionChoiceValue?

    public init(name: String, value: DiscordApplicationCommandOptionChoiceValue? = nil) {
        self.name = name
        self.value = value
    }

    init?(choiceObject: [String: Any]) {
        name = (choiceObject["name"] as? String) ?? ""
        let rawValue = choiceObject["value"]
        if let value = rawValue as? String {
            self.value = .string(value)
        } else if let value = rawValue as? Int {
            self.value = .int(value)
        } else {
            return nil
        }
    }
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

    /// A custom (developer-defined) id attached to e.g. a button interaction.
    public let customId: String?

    /// The params + values by the user
    public let options: [DiscordApplicationCommandInteractionDataOption]

    init(dataObject: [String: Any]) {
        id = Snowflake(dataObject["id"] as? String) ?? 0
        name = dataObject.get("name", as: String.self) ?? ""
        customId = dataObject["custom_id"] as? String
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
