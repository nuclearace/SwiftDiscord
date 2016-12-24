// The MIT License (MIT)
// Copyright (c) 2016 Erik Little

// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated
// documentation files (the "Software"), to deal in the Software without restriction, including without
// limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the
// Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

// The above copyright notice and this permission notice shall be included in all copies or substantial portions of the
// Software.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING
// BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO
// EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
// ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
// DEALINGS IN THE SOFTWARE.

import Foundation
#if !os(Linux)
import Starscream
#else
import WebSockets
#endif

/// Declares that a type will be an Engine for the Discord Gateway.
public protocol DiscordEngineSpec : class, DiscordEngineHeartbeatable, DiscordShard {
	// MARK: Properties

	/// A reference to the client this engine is associated with.
	weak var client: DiscordClientSpec? { get }

	/// The url to connect to.
	var connectURL: String { get }

	/// The type of engine. Used to correctly fire events.
	var engineType: String { get }

	/// The last received sequence number. Used for resume/reconnect.
	var lastSequenceNumber: Int { get }

	/// The session id of this engine.
	var sessionId: String? { get set }

	/// A reference to the underlying WebSocket. This is a WebSockets.Websocket on Linux and Starscream.WebSocket on
	/// macOS/iOS
	var websocket: WebSocket? { get }

	// MARK: Initializers

	/**
		The main initializer.

		- parameter client: The client this engine should be associated with.
	*/
	init(client: DiscordClientSpec, shardNum: Int, numShards: Int)

	// MARK: Methods

	/**
		Starts the connection to the Discord gateway.
	*/
	func connect()

	/**
		Disconnects the engine. An `engine.disconnect` is fired on disconnection.
	*/
	func disconnect()

	/**
		Logs that an error occured.

		- parameter message: The error message
	*/
	func error(message: String)

	/**
		Sends a gateway payload to Discord.

		- parameter payload: The payload object.
	*/
	func sendGatewayPayload(_ payload: DiscordGatewayPayload)
}

public extension DiscordEngineSpec {
	/// Default Implementation.
	func sendGatewayPayload(_ payload: DiscordGatewayPayload) {
		guard let payloadString = payload.createPayloadString() else {
			error(message: "Could not create payload string")

			return
		}

		DefaultDiscordLogger.Logger.debug("Sending ws: %@", type: engineType, args: payloadString)

		#if !os(Linux)
		websocket?.write(string: payloadString)
		#else
		try? websocket?.send(payloadString)
		#endif
	}
}
