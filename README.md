# SwiftDiscord

A Discord API client for Swift.

Features:
  - Sending voice (receiving voice coming soon)
  - Bot and User account support (OAuth coming soon)
  - REST API sperate from client. You can use the REST API separately (via the DiscordEndpoint enum) from the client if you wish.

Requirements:
  - macOS (I plan to eventually see what can be done on iOS)
  - ffmpeg installed via Homebrew (Make sure it is installed with opus support)
  - libsodium also installed via Homebrew.
  - Swift 3
  
  
Installing:
 - Create your Swift Package Manager project
 - Add `.Package(url: "https://github.com/nuclearace/SwiftDiscord", majorVersion: 0, minor: 1)` to your dependencies in Package.swift
 - Add `import SwiftDiscord` to files you wish to use the module in.
 - Run `swift build -Xlinker -L/usr/local/lib/`. The Xlinker option is needed to tell the package manager where to find the libsodium library that was installed through Homebrew.

See Sources/Runner for a basic example
