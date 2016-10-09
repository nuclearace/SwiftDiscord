import Foundation

public protocol DiscordEngineHeartbeatable : DiscordEngineSpec {
	var heartbeatInterval: Int { get }
	var heartbeatQueue: DispatchQueue { get }

	func startHeartbeat(seconds: Int)
	func sendHeartbeat()
}

public extension DiscordEngineHeartbeatable {
	func sendHeartbeat() {
		guard websocket?.isConnected ?? false else { return }

		// print("DiscordEngineHeartbeatable: about to send heartbeat")

		sendGatewayPayload(DiscordGatewayPayload(code: .heartbeat, payload: .integer(lastSequenceNumber)))

		let time = DispatchTime.now() + Double(Int64(heartbeatInterval * Int(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)

		heartbeatQueue.asyncAfter(deadline: time) {[weak self] in self?.sendHeartbeat() }
	}
}
