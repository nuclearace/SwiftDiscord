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
    - Install vapor dependencies:
        - `brew tap vapor/tap && brew install ctls` or `eval "$(curl -sL https://apt.vapor.sh)"; sudo apt-get install vapor;`
    - Create your Swift Package Manager project
    - Add `.package(url: "https://github.com/nuclearace/SwiftDiscord", .upToNextMajor(from: "6.0.0"))` to your dependencies in Package.swift
    - Add `import SwiftDiscord` to files you wish to use the module in.
    - Run `swift build`

Xcode:

If you wish to use Xcode with your Swift Package Manager project, you can do `swift package generate-xcodeproj`.  In Xcode 11 and higher, you can also add SwiftDiscord as a dependency under the `Link Binary With Libraries` section of the `Build Phases` tab of an existing Xcode project.

![](https://i.imgur.com/JR97eTO.png)

Usage
=====

Checkout the [getting started](https://nuclearace.github.io/SwiftDiscord/getting-started.html) page for a quickstart guide.

[Docs](https://nuclearace.github.io/SwiftDiscord/index.html)
============================================================
Docs are generated with [jazzy](https://github.com/realm/jazzy) using the magical command:

`jazzy --xcodebuild-arguments -project,SwiftDiscord.xcodeproj/,-scheme,SwiftDiscord-Package --documentation=UsageDocs/*.md --theme fullwidth --module SwiftDiscord`

*Must have setup an Xcode project*

Why no CocoaPods?
=================
I hate CocoaPods and the Swift Package Manager makes it easy to do system modules.
