import Foundation
import SwiftDiscord
import COPUS
import Sodium
import Socks

let queue = DispatchQueue(label: "Async Read")
let client = DiscordClient(token: "")

func readAsync() {
	queue.async {
		guard let input = readLine(strippingNewline: true) else { return readAsync() }

        if input == "quit" {
            client.disconnect()
        } else {
        	readAsync()
        }
	}
}

print("Type 'quit' to stop")
readAsync()

client.on("engine.disconnect") {data in
	print("Engine died, exiting")
	exit(0)
}

client.on("connect") {data in
	// print(client.guilds)
}

client.on("message") {data in
	guard let message = data[0] as? DiscordMessage else { fatalError("Didn't get message in message event") }

	print(message)
}

client.connect()

CFRunLoopRun()