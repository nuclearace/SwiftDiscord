//
// Created by Erik Little on 3/25/17.
//

import Foundation
import XCTest
@testable import SwiftDiscord

class TestDiscordEngine : XCTestCase, DiscordEngineDelegate {
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

    func engine(_ engine: DiscordEngine, didReceiveEvent event: DiscordDispatchEvent,
                with payload: DiscordGatewayPayload) {
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

    func engine(_ engine: DiscordEngine, gotHelloWithPayload payload: DiscordGatewayPayload) {
        XCTAssertTrue(engine.connected, "Engine should be connected after getting hello")

        expectation.fulfill()
    }

    let token = "Testing" as DiscordToken

    var engine: DiscordEngine!
    var expectation: XCTestExpectation!

    override func setUp() {
        engine = DiscordEngine(delegate: self)
    }
}
