# SwiftDiscord

[![Build Status](https://travis-ci.org/nuclearace/SwiftDiscord.svg?branch=master)](https://travis-ci.org/nuclearace/SwiftDiscord)

A Discord API client for Swift.

- Features:
  - Sending and receiving voice.
  - macOS, iOS, and Linux\*\* support.
  - Bot and User account support.
  - REST API separate from client. You can use the REST API separately to build your own client if you wish.
  - Configurable sharding.

\*\* - Linux stability is currently limited to the stability of open source Foundation, but in thoery should support everything.

- Requirements:
  - libopus
  - libsodium
  - Swift 3

- Recommendend:
  - ffmpeg (Without FFmpeg you must send raw audio)


- Installing and Building (Linux and macOS):
 - Create your Swift Package Manager project
 - Add `.Package(url: "https://github.com/nuclearace/SwiftDiscord", majorVersion: 2)` to your dependencies in Package.swift
 - Add `import SwiftDiscord` to files you wish to use the module in.
 - Run `swift build -Xlinker -L/usr/local/lib -Xlinker -lopus -Xcc -I/usr/local/include`. The Xlinker options are needed to tell the package manager where to find the libsodium and opus libraries that were installed through Homebrew. The Xcc option tells clang where to find the headers for opus.

Xcode:

If you wish to use Xcode with your Swift Package Manager project, you can do `swift package generate-xcodeproj`. However after doing that, you'll have to make a change to SwiftDiscord's build settings. Just like when compiling from the command line, we have to tell Xcode where to find libsodium and libopus. This can be done by adding `/usr/local/lib` to the library search paths and `/usr/local/include` to the header search paths. This should be done for the SwiftDiscord and DiscordOpus targets. The DiscordOpus target also needs the `-lopus` option in "Other Linker Flags".

![](https://i.imgur.com/JR97eTO.png)

Usage
=====

Checkout the [getting started](https://nuclearace.github.io/SwiftDiscord/getting-started.html) page for a quickstart guide.

[Docs](https://nuclearace.github.io/SwiftDiscord/index.html)
============================================================
Docs are generated with [jazzy](https://github.com/realm/jazzy) using the magical command:

`jazzy --xcodebuild-arguments -project,SwiftDiscord.xcodeproj/,-scheme,SwiftDiscord --documentation=UsageDocs/*.md`

*Must have setup an Xcode project*

Why no CocoaPods?
=================
I hate CocoaPods and the Swift Package Manager makes it easy to do system modules.
