import Foundation

public protocol DiscordEngineHeartbeatable {
	var heartbeatInterval: Int { get }
	var heartbeatQueue: DispatchQueue { get }

	func startHeartbeat(seconds: Int)
	func sendHeartbeat()
}
