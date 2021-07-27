import Foundation

/// Represents a slash-command. The base command model of the
/// application.
public struct DiscordApplicationCommand: Codable, Identifiable {
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
}

public struct DiscordApplicationCommandOption: Codable {
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
}

public struct DiscordApplicationCommandOptionChoice: Codable {
    /// 1-100 character choice name
    public let name: String

    /// Value of the choice
    public let value: DiscordApplicationCommandOptionChoiceValue?

    public init(name: String, value: DiscordApplicationCommandOptionChoiceValue? = nil) {
        self.name = name
        self.value = value
    }
}

public enum DiscordApplicationCommandOptionChoiceValue: Codable {
    case string(String)
    case int(Int)

    public init(from decoder: Decoder) throws {
        let container = try container.singleValueContainer()
        if let s = try? container.decode(String.self) {
            self = .string(s)
        } else {
            let i = try container.decode(Int.self)
            self = .int(i)
        }
    }

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

public enum DiscordApplicationCommandOptionType: Int, Codable {
    case subCommand = 1
    case subCommandGroup = 2
    case string = 3
    case integer = 4
    case boolean = 5
    case user = 6
    case channel = 7
    case role = 8
}

public struct DiscordApplicationCommandInteractionData: Codable {
    public enum CodingKeys: String, CodingKey {
        case id
        case name
        case customId = "custom_id"
        case options
    }

    /// The ID of the invoked command
    public let id: CommandID

    /// The name of the invoked command
    public let name: String

    /// A custom (developer-defined) id attached to e.g. a button interaction.
    public let customId: String?

    /// The params + values by the user
    public let options: [DiscordApplicationCommandInteractionDataOption]
}

public struct DiscordApplicationCommandInteractionDataOption: Codable {
    /// The name of the parameter.
    public let name: String

    /// The value of the pair. Type is the OptionType of the command.
    public let value: Any?

    /// Present if this option is a group or subcommand.
    public let options: [DiscordApplicationCommandInteractionDataOption]?
}
