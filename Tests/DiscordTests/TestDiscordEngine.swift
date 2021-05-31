//
// Created by Erik Little on 3/25/17.
//

import Foundation
import XCTest
import NIO
@testable import Discord

public class TestDiscordEngine : XCTestCase, DiscordShardDelegate {
    func testEngineCorrectlyHandlesHelloPacket() {
        expectation = expectation(description: "Engine should be connected after receiving hello packet")

        engine.parseGatewayMessage(helloPacket)

        waitForExpectations(timeout: 0.2)
    }

    func testEngineSetsSessionIdFromReadyPacket() {
        expectation = expectation(description: "Engine should set the session id from a ready packet")

        engine.parseGatewayMessage(readyPacket)

        waitForExpectations(timeout: 0.2)
    }

    func testEngineUpdatesSequenceNumber() {
        let payload1 = DiscordGatewayPayload(code: .gateway(.dispatch), payload: .object([:]), sequenceNumber: 1,
                                             name: DiscordDispatchEvent.messageCreate.rawValue)
        let payload2 = DiscordGatewayPayload(code: .gateway(.dispatch), payload: .object([:]), sequenceNumber: 2,
                                             name: DiscordDispatchEvent.messageUpdate.rawValue)

        expectation = expectation(description: "Engine should update the sequence number")

        engine.handleGatewayPayload(payload1)
        engine.handleGatewayPayload(payload2)

        waitForExpectations(timeout: 0.2)
    }

    var engine: DiscordEngine!
    var expectation: XCTestExpectation!
    var loop: MultiThreadedEventLoopGroup!

    public static var allTests: [(String, (TestDiscordEngine) -> () -> ())] {
        return [
            ("testEngineCorrectlyHandlesHelloPacket", testEngineCorrectlyHandlesHelloPacket),
            ("testEngineSetsSessionIdFromReadyPacket", testEngineSetsSessionIdFromReadyPacket),
            ("testEngineUpdatesSequenceNumber", testEngineUpdatesSequenceNumber),
        ]
    }

    public override func setUp() {
        loop = MultiThreadedEventLoopGroup(numberOfThreads: 1)
        engine = DiscordEngine(delegate: self, intents: .unprivilegedIntents, onLoop: loop.next())
    }
}

public extension TestDiscordEngine {
    var token: DiscordToken {
        return "Testing"
    }

    func shard(_ shard: DiscordShard, didReceiveEvent event: DiscordDispatchEvent,
                with payload: DiscordGatewayPayload) {
        let engine = shard as! DiscordEngine

        switch event {
        case .ready:
            XCTAssertEqual(engine.sessionId, "hello_world", "Engine should correctly set the session id")
            expectation.fulfill()
        case .messageCreate:
            XCTAssertEqual(engine.lastSequenceNumber, 1, "Engine should correctly set the last sequence number")
        case .messageUpdate:
            XCTAssertEqual(engine.lastSequenceNumber, 2, "Engine should correctly set the last sequence number")
            expectation.fulfill()
        default:
            return
        }
    }

    func shard(_ shard: DiscordShard, gotHelloWithPayload payload: DiscordGatewayPayload) {
        XCTAssertTrue(engine.connected, "Engine should be connected after getting hello")

        expectation.fulfill()
    }

    func shardDidConnect(_ shard: DiscordShard) { }

    func shardDidDisconnect(_ shard: DiscordShard) { }
}
