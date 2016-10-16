# SwiftDiscord

A very WIP discord client API.

Requirements:
  - macOS (I plan to eventually see what can be done on iOS)
  - ffmpeg installed via Homebrew (Make sure it is installed with opus support)
  - libsodium also installed via Homebrew.
  - Swift 3
  
  
Installing:
 - Create your Swift Package Manager project
 - Add `.Package(url: "https://github.com/nuclearace/SwiftDiscord", majorVersion: 0, minor: 1)` to your dependencies in Package.swift
 - Run `swift build -Xlinker -L/usr/local/lib/`. The Xlinker option is needed to tell the package manager where to find the libsodium library that was installed through Homebrew.
 - Add `import SwiftDiscord` to files you wish to use the module in.

See Sources/Runner for a basic example
