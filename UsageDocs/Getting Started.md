Getting Started
===============

The first thing that you'll need is a Discord JWT. These can be obtained by going to [your apps](https://discordapp.com/developers/applications/me) and selecting/making one. Then on the app page click "click to reveal".

Once you have your token you can start writing some code.

Configuring the client
----------------------
_All of these steps assume you are working inside of a class that conforms to
[DiscordClientDelegate](./Protocols/DiscordClientDelegate.html)_


Configuring the client is straightforward. The intializer for the client takes the JWT we got in the previous step, and an optinal array of configuration options.

```swift
// client must be `DiscordClient!`
self.client = DiscordClient(token: "Bot myjwt.from.discord", delegate: self, configuration: [.log(.info)])
```

It's important to note that we've added "Bot" in front of the token. This is tell Discord that this token represents a bot token. This is required unless the token is a user token. If the token is an OAuth token then the token should be prefaced with "Bearer". The configuration used in this example turns on the most basic logging. More about the different configurations available can be found on the [DiscordClientOption](./Enums/DiscordClientOption.html) page.

Once we have the client initialized, it's time to add any delegate methods that we want to listen for.

```swift
func client(_ client: DiscordClient, didConnect connected: Bool) {
    print("Bot connected!")
}

func client(_ client: DiscordClient, didCreateMessage message: DiscordMessage) {
    if message.content == "$mycommand" {
        message.channel?.send("I got your command")
    }
}

```

In this code we've added two delegate methods. The `client(_ client: DiscordClient, didConnect connected: Bool)` method is called once all shards have connected. It's best to wait until this event is received before trying to do anything with the client, otherwise the client might not be fully populated with Guild and Channel information.

The `client(_ client: DiscordClient, didCreateMessage message: DiscordMessage)` method is called whenever a message is received from the gateway. This particular implemenation just checks if the content of the message is a command, and if it is, sends a response.

Connecting the client
---------------------

Once we've configured our delegate methods, we're ready to connect to Discord. This is as simple as:

```swift
client.connect()
```

Once the client is done connecting, the connect delegate method will be called and we're good to start interacting with Discord!

More detail?
------------
A living bot example can be found [here](https://github.com/nuclearace/SwiftBot). This bot shows more complicated interaction with client such as getting roles for a user, getting guild channels, sending files to Discord and streaming audio to Discord.