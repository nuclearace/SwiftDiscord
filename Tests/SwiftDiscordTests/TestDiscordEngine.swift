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

    func engine(_ engine: DiscordEngine, didReceiveEvent event: DiscordDispatchEvent,
                with payload: DiscordGatewayPayload) {
        switch event {
        case .ready:
            XCTAssertEqual(engine.sessionId, "hello_world", "Engine should correctly set the session id")
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
