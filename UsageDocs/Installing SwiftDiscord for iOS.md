# Installing SwiftDiscord for iOS

**Please note that you should follow the instructions in this document rather than in the main README if you intend to build for iOS.**

## Prerequisites

* SwiftDiscord **6**
* Xcode **9.0**
* iOS SDK **11.0**
* Homebrew

I have absolutely no idea if this will continue to work with future or previous versions of SwiftDiscord/Xcode/iOS. Your mileage may vary.

## Instructions

You may be tempted to skip some steps or to not follow them in order. If you'd like to get this working at any point within the next few hours, it is highly recommended you **do not do that**. If you do somehow get this to work without completing a certain step, please let me know so I can update the instructions.

1. Install dependencies: `brew tap vapor/tap && brew install ctls && brew install opus && brew install libsodium`
2. Make your project folder: `mkdir SwiftDiscord-iOS && cd SwiftDiscord`
3. Initialize a new Swift package: `swift package init --type executable`
4. Modify your `Package.swift` so you have SwiftDiscord as a dependency:

	```swift
	// swift-tools-version:3.1
	
	import PackageDescription
	
	let package = Package(
		// you can replace name (below) with a string of your choosing, the xcode project that is generated will have this name
	    name: "SwiftDiscord-iOS",
	    dependencies: [
	     .Package(url: "https://github.com/nuclearace/SwiftDiscord", majorVersion: 6)
	    ]
	)
	```
5. Download SwiftDiscord: `swift package update`
6. Build SwiftDiscord: `swift build -Xlinker -L/usr/local/lib -Xlinker -lopus -Xcc -I/usr/local/include`
7. Now comes the hardest part: `mkdir libs`
		
	1. Manually compile & build the following projects:
		* [Sodium](https://github.com/jedisct1/libsodium)
		* [Opus for iOS](https://github.com/chrisballinger/Opus-iOS)
		* [OpenSSL for iPhone](https://github.com/x2on/OpenSSL-for-iPhone)

		
		I hope you like reading READMEs.
	
	2. Move the resulting compiled libraries (.a files) into your new `libs` directory. You should have the following files in there:
		* `libcrypto.a`
		* `libopus.a`
		* `libsodium.a`
		* `libssl.a`

8. To be honest, I'm not expecting anyone to make it past the last step, so if by some miracle you actually managed to fill `libs` with the required libs, give yourself a pat on the back. Go make coffee or something.
9.  Generate an Xcode project and open it: `swift package generate-xcodeproj && open SwiftDiscord-iOS`
10. In the *Build Settings* for the `SwiftDiscord` target:
	1. Add the following to `Valid Architectures`: `arm64` `armv7` `armv7s`
	2. Add your `libs` folder to the `Library Search Paths`: `$(SRCROOT)/libs`
		* You may need to switch from `Basic` to `All` Build Settings in order to see this key.
	3. Also add `/usr/local/lib` to your `Library Search Paths`, **after** your own `libs` folder.
	4. Add `/usr/local/include` to your `Header Search Paths`.
11. In the *Build Settings* for the `DiscordOpus` target:
	1. Repeat steps 2, 3, and 4 from the previous target, but for this target's settings of course.
12. In the *Build Settings* for the `URI` target:
	1. Add your `libs` folder to the `Library Search Paths`: `$(SRCROOT)/libs`
	2. Make sure `$(PROJECT_TEMP_DIR)/SymlinkLibs/` is still included in the search path and that it is **above** the `libs` path you just added.
	3. Copy the `Library Search Paths` (just select the row and Cmd+C).
13. In the Build Settings for the `Crypto`, `CHTTP`, `HTTP`, `TLS`, and `WebSockets` targets:
	1. Overwrite the `Library Search Paths` with the paths stored on your clipboard (Cmd+V).
14. Create a new Single View Application target (I'll call it `TestiOS` but you do you)
15. In the `Build Settings` for the `TestiOS` target, copy and paste the `Header Search Paths` from the `SwiftDiscord` target 

	* Not just the one we added - grab the ones that were there before too
	
16. In the *Build Phases* for the `TestiOS` target:

	1. Add `SwiftDiscord` to **Target Dependencies**
	2. Add `libcrypto.a`, `libopus.a`, `libsodium.a`, and `libssl.a` under **Link Binary with Libraries**.
	3. Create a new **Copy Files Build Phase** (there's a + button at the upper left side [under the General tab] that lets you do this).
		* Set its destination to `Frameworks`
		* Add everything in the **Products** folder (should all be .frameworks) except for `TestiOS.app`
17. Replace your `ViewController.swift` contents with the following code to make sure everything works correctly:

	```swift
	import UIKit
	import Discord

	class ViewController: UIViewController, DiscordClientDelegate {
	    
	    var client: DiscordClient!
	    
	    override func viewDidLoad() {
	        super.viewDidLoad()
	        self.client = DiscordClient(token: "some valid token here", delegate: self, configuration: [.log(.info)])
	        client.connect()
	    }
	    
	    func client(_ client: DiscordClient, didConnect connected: Bool) {
	        print("Bot connected!")
	    }
	    
	    func client(_ client: DiscordClient, didCreateMessage message: DiscordMessage) {
	        if message.content == "$mycommand" {
	            message.channel?.send("I got your command")
	        }
	    }
	    
	    func client(_ client: DiscordClient, needsDataSourceForEngine engine: DiscordVoiceEngine) throws -> DiscordVoiceDataSource {
	        return try DiscordBufferedVoiceDataSource(
	            opusEncoder: DiscordOpusEncoder(bitrate: 128_000, sampleRate: 48_000, channels: 2)
	        )
	    }
	}
	``` 
18. Build!
	* If you have hundreds of warnings, you may want to run a Product > Clean and restart Xcode.
19. Run!
20. You did it. Somehow. Congratulations!

## Thanks

I'd like to thank the lead developer (nuclearace) for providing guidance throughout the whole journey; without whom I would have undoubtedly never been able to get this working. 

Cheers,

[Andi](http://twitter.com/nexuist)

## Troubleshooting

If you experience issues and you are positive you followed the instructions *exactly* (no, really, if you miss one step you'll probably get 400+ warnings and several build errors), I recommend you [file an issue](https://github.com/nuclearace/SwiftDiscord/issues/new) first. You can also talk to me on [Twitter]((https://twitter.com/nexuist)).


Happy Swifting! (is that a thing? I don't know. It is now).
