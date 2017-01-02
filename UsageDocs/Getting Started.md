Getting Started
===============

The first thing that you'll need is a Discord JWT. These can be obtained by going to [your apps](https://discordapp.com/developers/applications/me) and selecting/making one. Then on the app page click "click to reveal".

Once you have your token you can start writing some code.

Configuring the client
----------------------

Configuring the client is straightforward. The intializer for the client takes the JWT we got in the previous step, and an optinal array of configuration options.

```swift
let client = DiscordClient(token: "Bot myjwt.from.discord", configuration: [.log(.info)])
```

It's important to note that we've added "Bot" in front of the token. This is tell Discord that this token represents a bot token. This is required unless the token is a user token. If the token is an OAuth token then the token should be prefaced with "Bearer". The configuration used in this example turns on the most basic logging. More about the different configurations available can be found on the [DiscordClientOption](./Enums/DiscordClientOption.html) page.

Once we have the client initialized, it's time to add any handlers that we want to listen for.

```swift
client.on("connect") {data in
    print("The client is connected")
}

client.on("messageCreate") {data in
    guard let message = data[0] as? DiscordMessage else { return }

    if message.content == "$mycommand" {
        message.channel?.sendMessage("I got your command")
    }
}
```

In this code we've added two event handlers. One for the `connect` event, and one for the `messageCreate` event. The `connect` event is fired once all shards have connected. It's best to wait until this event is received before trying to do anything with the client, otherwise the client might not be fully populated with Guild and Channel information.

The `messageCreate` event is fired whenever a message is received from the gateway. The handler in this case first sanity checks that the first thing received in the handler's data is in fact a message. Once it is sure it's dealing with a message, it checks if the message's content is the command "mycommand", and if it is, sends a response to the channel that the message originated from.

Connecting the client
---------------------

Once we've configured our event listeners, we're ready to connect to Discord. This is as simple as:

```swift
client.connect()
```

Once the client is done connecting, our `connect` event will fire and we're good to start interacting with Discord!

More detail?
------------
A living bot example can be found in `Sources/ExampleBot`. This bot shows more complicated interaction with client such as getting roles for a user, getting guild channels, sending files to Discord and streaming audio to Discord.