//
//  SingleEventTests.swift
//
//  Created by Jan Cislinsky on 15. 12. 2017.
//  Copyright © 2017 ETLiveData. All rights reserved.
//

import Foundation
import XCTest
@testable import ETBinding

class SingleEventTests: XCTestCase {

    private var expectations: [XCTestExpectation]!
    private var singleEvent: SingleEvent<String>!
    private var singleEventVoid: SingleEvent<Void>!

    override func setUp() {
        super.setUp()
        singleEvent = SingleEvent<String>()
        singleEventVoid = SingleEvent<Void>()
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

        _ = singleEvent.observeSingleEventForever(onUpdate: onUpdate)
        singleEvent.trigger(expectations[0].expectationDescription)

        waitForExpectations(timeout: 1, handler: nil)
    }

    func testTriggerVoid() {
        var triggered = false
        _ = singleEventVoid.observeSingleEventForever(onUpdate: {
            triggered = true
        })
        singleEventVoid.trigger()
        XCTAssertTrue(triggered)
    }

    func testTriggerMultipleTimes() {
        expectations = [expectation(description: "New data 1")]

        _ = singleEvent.observeSingleEventForever(onUpdate: onUpdate)
        let arg1 = expectations[0].expectationDescription
        singleEvent.trigger(arg1)

        expectFatalError(withMessage: "Unable to trigger SingleEvent multiple times.") {
            self.singleEvent.trigger(arg1)
        }
    }

    func testRemoveObserver() {
        let observer1 = Observer<String>(update: onUpdate)
        let observer2 = Observer<String>(update: onUpdate)

        singleEvent.observeSingleEventForever(observer: observer1)
        XCTAssert(singleEvent.observers.count == 1)

        singleEvent.observeSingleEventForever(observer: observer2)
        XCTAssert(singleEvent.observers.count == 2)

        XCTAssert(singleEvent.contains(observer1))
        XCTAssert(singleEvent.contains(observer2))

        singleEvent.remove(observer: observer1)
        XCTAssert(singleEvent.observers.count == 1)
        XCTAssertFalse(singleEvent.contains(observer1))
        XCTAssert(singleEvent.contains(observer2))

        singleEvent.remove(observer: observer2)
        XCTAssert(singleEvent.observers.isEmpty)
    }

    func testQueueWhereValueIsDispatched() {
        expectations = [expectation(description: "New data 1")]
        let queue = makeQueueWithKey()
        let observer = Observer<String>(update: curry(onUpdate)(queue.0))

        singleEvent.observeSingleEventForever(observer: observer)
        queue.1.sync {
            singleEvent.trigger(expectations[0].expectationDescription)
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
