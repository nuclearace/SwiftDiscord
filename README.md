# Discord Client for Swift

[![Linux](https://github.com/fwcd/swift-discord/actions/workflows/linux.yml/badge.svg)](https://github.com/fwcd/swift-discord/actions/workflows/linux.yml)
[![Docs](https://github.com/fwcd/swift-discord/actions/workflows/docs.yml/badge.svg)](https://fwcd.github.io/swift-discord)

A Discord API client library for Swift.

## Example

```swift
import Discord
import Dispatch

class Bot: DiscordClientDelegate {
    private var client: DiscordClient!

    init() {
        client = DiscordClient(token: "Bot myjwt.from.discord", delegate: self)
        client.connect()
    }

    func client(_ client: DiscordClient, didCreateMessage message: DiscordMessage) {
        if message.content == "ping" {
            message.channel?.send("pong")
        }
    }
}

let bot = Bot()
dispatchMain()
```

## Features

- macOS and Linux support
- v8 API (including interactions, slash commands and message components)
- Configurable sharding
- Voice support

## Requirements

- Swift 5+
- `libopus`
- `libsodium`
- Recommended: `ffmpeg` (Without FFmpeg you must send raw audio)

## Building

`swift build`

## Usage

Checkout the [getting started](https://nuclearace.github.io/SwiftDiscord/getting-started.html) page for a quickstart guide.
