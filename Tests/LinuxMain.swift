import XCTest
import DiscordTests

XCTMain([testCase(TestDiscordClient.allTests),
         testCase(TestDiscordDataStructures.allTests),
         testCase(TestDiscordEngine.allTests),
         testCase(TestDiscordGuild.allTests),
         testCase(TestDiscordGuildMember.allTests),
         testCase(TestDiscordPermissions.allTests),
         testCase(TestDiscordMessage.allTests)
        ])
