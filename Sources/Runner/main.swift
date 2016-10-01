import Foundation
import SwiftDiscord

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

client.connect()

CFRunLoopRun()