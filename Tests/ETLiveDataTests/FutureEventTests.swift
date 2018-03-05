//
//  FutureEventTests.swift
//
//  Created by Jan Cislinsky on 15. 12. 2017.
//  Copyright © 2017 ETLiveData. All rights reserved.
//

import Foundation
import XCTest
@testable import ETBinding

class FutureEventTests: XCTestCase {

    private var expectations: [XCTestExpectation]!
    private var futureEvent: FutureEvent<String>!
    private var futureEventVoid: FutureEvent<Void>!

    override func setUp() {
        super.setUp()
        futureEvent = FutureEvent<String>()
        futureEventVoid = FutureEvent<Void>()
    }

    func onUpdate(_ input: String?) {
        onUpdate(queueKey: nil, input)
    }

    func onUpdate(queueKey: DispatchSpecificKey<Void>?, _ input: String?) {
        if let queueKey = queueKey {
            expectQueue(withKey: queueKey)
        }
        guard expectations.isEmpty == false else {
            XCTAssert(expectations.isEmpty == false, "Update called more than expected")
            return
        }
        XCTAssert(input == expectations[0].expectationDescription, "Observer receives invalid data")
        expectations[0].fulfill()
        expectations.removeFirst()
    }

    // MARK: -

    func testTrigger() {
        expectations = [expectation(description: "New data 1")]

        _ = futureEvent.observeForever(onUpdate: onUpdate)
        futureEvent.trigger(expectations[0].expectationDescription)

        waitForExpectations(timeout: 1, handler: nil)
    }

    func testTriggerVoid() {
        var triggered = false
        _ = futureEventVoid.observeForever(onUpdate: {
            triggered = true
        })
        futureEventVoid.trigger()
        XCTAssertTrue(triggered)
    }

    func testTriggerMultipleTimes() {
        expectations = [expectation(description: "New data 1"), expectation(description: "New data 1")]

        _ = futureEvent.observeForever(onUpdate: onUpdate)
        let arg1 = expectations[0].expectationDescription
        let arg2 = expectations[1].expectationDescription
        futureEvent.trigger(arg1)
        futureEvent.trigger(arg2)

        waitForExpectations(timeout: 1, handler: nil)
    }

    func testQueueWhereValueIsDispatched() {
        expectations = [expectation(description: "New data 1")]
        let queue = makeQueueWithKey()
        let observer = Observer<String>(update: curry(onUpdate)(queue.0))

        futureEvent.observeForever(observer: observer)
        queue.1.sync {
            futureEvent.trigger(expectations[0].expectationDescription)
        }

        waitForExpectations(timeout: 1, handler: nil)
    }

    static var allTests = [
        ("testTrigger", testTrigger),
        ("testTriggerVoid", testTriggerVoid),
        ("testTriggerMultipleTimes", testTriggerMultipleTimes),
        ("testQueueWhereValueIsDispatched", testQueueWhereValueIsDispatched),
        ]
}

private class Owner {}

