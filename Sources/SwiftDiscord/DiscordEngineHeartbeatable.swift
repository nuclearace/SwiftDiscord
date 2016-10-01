import Foundation

public protocol DiscordEngineHeartbeatable : DiscordEngineSpec {
	var heartbeatInterval: Int { get }
	var heartbeatQueue: DispatchQueue { get }

	func startHeartbeat(seconds: Int)
	func sendHeartbeat()
}

public extension DiscordEngineHeartbeatable {
	func sendHeartbeat() {
		print("DiscordEngineHeartbeatable: about to send heartbeat")

		let payload = DiscordGatewayPayload(code: .heartbeat, payload: .integer(lastSequenceNumber))

		sendGatewayPayload(payload)

		let time = DispatchTime.now() + Double(Int64(heartbeatInterval * Int(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)

		heartbeatQueue.asyncAfter(deadline: time) {[weak self] in self?.sendHeartbeat() }
	}
}
