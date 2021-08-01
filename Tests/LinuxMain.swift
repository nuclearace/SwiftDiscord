import XCTest
import DiscordTests

XCTMain([testCase(TestDiscordClient.allTests),
         testCase(TestDiscordDataStructures.allTests),
         testCase(TestDiscordEngine.allTests),
         testCase(TestDiscordPermissions.allTests),
         testCase(TestDiscordMessage.allTests)
        ])
