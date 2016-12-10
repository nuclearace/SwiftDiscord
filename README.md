# SwiftDiscord

A Discord API client for Swift.

- Features:
  - Sending and receiving voice
  - macOS and iOS support (iOS currently does not support voice)
  - Bot and User account support (OAuth coming soon)
  - REST API separate from client. You can use the REST API separately to build your own client if you wish.

- Requirements:
  - ffmpeg installed via Homebrew (Make sure it is installed with opus support)
  - libsodium also installed via Homebrew.
  - Swift 3


- Installing:
 - Create your Swift Package Manager project
 - Add `.Package(url: "https://github.com/nuclearace/SwiftDiscord", majorVersion: 0, minor: 3)` to your dependencies in Package.swift
 - Add `import SwiftDiscord` to files you wish to use the module in.
 - Run `swift build -Xlinker -L/usr/local/lib/`. The Xlinker option is needed to tell the package manager where to find the libsodium library that was installed through Homebrew.

Xcode:

If you wish to use Xcode with your Swift Package Manager project, you can do `swift package generate-xcodeproj`. However after doing that, you'll have to make a change to SwiftDiscord's build settings. Just like when compiling from the command line, we have to tell Xcode where to find libsodium. This can be done by adding `/usr/local/lib` to the library search paths.

![](https://i.imgur.com/JR97eTO.png)

You'll then want to remove all target dependencies and linked libraries except for Starscream and Socks**. (The others are used on Linux, but not macOS or iOS).

![](https://i.imgur.com/vhhnfJp.png)

** - Socks should be removed on iOS as voice is not supported on it.

See Sources/Runner for a basic example

[Docs](https://nuclearace.github.io/SwiftDiscord/index.html)
============================================================
Docs are generated with [jazzy](https://github.com/realm/jazzy) using the magical command:

`jazzy --xcodebuild-arguments -project,SwiftDiscord.xcodeproj/,-scheme,SwiftDiscord`

*Must have setup an Xcode project*

Why no CocoaPods?
=================
I hate CocoaPods and the Swift Package Manager makes it easy to do system modules.
