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
    private var owner: Owner!
    private var singleEvent: SingleEvent<String>!
    private var singleEventVoid: SingleEvent<Void>!

    override func setUp() {
        super.setUp()
        owner = Owner()
        singleEvent = SingleEvent<String>()
        singleEventVoid = SingleEvent<Void>()
    }

    func onUpdate(_ input: String?) {
        update(queueKey: nil, input)
    }

    func update(queueKey: DispatchSpecificKey<Void>?, _ input: String?) {
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

    // MARK: - Single event observable tests

    func testObserveWithObserverAndLifecycleOwner() {
        let observer = Observer<String>(update: onUpdate)
        singleEvent.observeSingleEvent(owner: owner!, observer: observer)
        XCTAssert(singleEvent.observers.count == 1)
        XCTAssert(singleEvent.contains(observer))
    }

    func testObserveWithOnUpdateAndLifecycleOwner() {
        let observer = singleEvent.observeSingleEvent(owner: owner!, onUpdate: onUpdate)
        XCTAssertNotNil(observer)
        XCTAssert(singleEvent.observers.count == 1)
        XCTAssert(singleEvent.contains(observer))
    }

    func testObserveForeverWithObserver() {
        let observer = Observer<String>(update: onUpdate)
        singleEvent.observeSingleEventForever(observer: observer)
        XCTAssert(singleEvent.observers.count == 1)
        XCTAssert(singleEvent.contains(observer))
    }

    func testObserveForeverWithOnUpdate() {
        let observer = singleEvent.observeSingleEventForever(onUpdate: onUpdate)
        XCTAssert(singleEvent.observers.count == 1)
        XCTAssert(singleEvent.contains(observer))
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

    func testRemoveObserverOnDealloc() {
        let observer = singleEvent.observeSingleEvent(owner: owner!, onUpdate: onUpdate)
        XCTAssertNotNil(observer)
        XCTAssert(singleEvent.observers.count == 1)
        XCTAssert(singleEvent.contains(observer))

        // Deallocs owner
        owner = nil

        XCTAssertFalse(singleEvent.remove(observer: observer))
        XCTAssert(singleEvent.observers.isEmpty)
        XCTAssertFalse(singleEvent.contains(observer))
    }

    func testMultipleObserversForLifecycleOwner() {
        let numberOfObservers = 1000
        let observers = Array(1...numberOfObservers).map { (counter) -> (Observer<String>) in
            let observer = singleEvent.observeSingleEvent(owner: owner!, onUpdate: onUpdate)
            XCTAssert(singleEvent.observers.count == counter)
            XCTAssertNotNil(observer)
            XCTAssert(singleEvent.contains(observer))
            return observer
        }

        // Deallocs owner
        owner = nil

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            observers.forEach {
                XCTAssertFalse(self.singleEvent.contains($0))
                XCTAssertFalse(self.singleEvent.remove(observer: $0))
            }

            XCTAssert(self.singleEvent.observers.isEmpty)
        }
    }

    func testAddObserverMultipleTimes() {
        let observer = Observer<String>(update: onUpdate)
        expectFatalError(withMessage: "Unable to register same observer multiple time") {
            self.singleEvent.observeSingleEventForever(observer: observer)
            self.singleEvent.observeSingleEventForever(observer: observer)
        }
    }

    func testRemoveObserverMultipleTimes() {
        let observer = Observer<String>(update: onUpdate)
        self.singleEvent.observeSingleEventForever(observer: observer)
        XCTAssertTrue(singleEvent.remove(observer: observer))
        XCTAssertFalse(singleEvent.remove(observer: observer))
    }

    func testAddRemoveAddRemoveObserver() {
        let observer = Observer<String>(update: onUpdate)

        singleEvent.observeSingleEventForever(observer: observer)

        XCTAssert(singleEvent.contains(observer))
        XCTAssertTrue(singleEvent.remove(observer: observer))
        XCTAssertFalse(singleEvent.contains(observer))

        singleEvent.observeSingleEventForever(observer: observer)

        XCTAssert(singleEvent.contains(observer))
        XCTAssertTrue(singleEvent.remove(observer: observer))
        XCTAssertFalse(singleEvent.contains(observer))
        XCTAssertFalse(singleEvent.remove(observer: observer))
        XCTAssert(singleEvent.observers.isEmpty)
    }

    func testObserveDoesntFire() {
        var wasCalled = false
        _ = singleEvent.observeSingleEventForever(onUpdate: { input in
            wasCalled = true
        })
        XCTAssertFalse(wasCalled)
    }

    func testThreadSafety() {
        let cycles = 1000

        for i in 1...cycles {
            let exp = expectation(description: "New data \(i)")
            let observer = Observer<String>(update: onUpdate)
            DispatchQueue.global().async {
                self.singleEvent.observeSingleEventForever(observer: observer)
                DispatchQueue.global().async {
                    self.singleEvent.remove(observer: observer)
                    exp.fulfill()
                }
            }
        }

        waitForExpectations(timeout: 10) { error in
            XCTAssert(self.singleEvent.observers.isEmpty)
            XCTAssert(self.singleEvent.observers.isEmpty, "Observers still registered")
        }
    }

    // MARK: - Single event tests

    func testTrigger() {
        expectations = [expectation(description: "New data 1")]

        _ = singleEvent.observeSingleEventForever(onUpdate: onUpdate)
        singleEvent.trigger(expectations[0].expectationDescription)

        waitForExpectations(timeout: 10, handler: nil)
    }

    func testTriggerVoid() {
        var triggered = false
        _ = singleEventVoid.observeSingleEventForever(onUpdate: {
            triggered = true
        })
        singleEventVoid.trigger()
        XCTAssertTrue(triggered)
    }

    func testObserveAfterTrigger() {
        singleEvent.trigger("Test")
        expectFatalError(withMessage: "Unable to observe SingleEvent thas was already triggered.") {
            _ = self.singleEvent.observeSingleEventForever(onUpdate: self.onUpdate)
        }
    }

    func testTriggerMultipleTimes() {
        expectations = [expectation(description: "New data 1")]

        _ = singleEvent.observeSingleEventForever(onUpdate: onUpdate)
        let arg1 = expectations[0].expectationDescription
        singleEvent.trigger(arg1)

        waitForExpectations(timeout: 10, handler: nil)

        expectFatalError(withMessage: "Unable to trigger SingleEvent multiple times.") {
            self.singleEvent.trigger(arg1)
        }
    }

    func testQueueWhereValueIsDispatched() {
        expectations = [expectation(description: "New data 1")]
        let queue = makeQueueWithKey()
        let observer = Observer<String>(update: curry(update)(queue.0))

        singleEvent.observeSingleEventForever(observer: observer)
        queue.1.sync {
            singleEvent.trigger(expectations[0].expectationDescription)
        }

        waitForExpectations(timeout: 10, handler: nil)
    }

    static var allTests = [
        ("testObserveWithObserverAndLifecycleOwner", testObserveWithObserverAndLifecycleOwner),
        ("testObserveWithOnUpdateAndLifecycleOwner", testObserveWithOnUpdateAndLifecycleOwner),
        ("testObserveForeverWithObserver", testObserveForeverWithObserver),
        ("testObserveForeverWithOnUpdate", testObserveForeverWithOnUpdate),
        ("testRemoveObserver", testRemoveObserver),
        ("testRemoveObserverOnDealloc", testRemoveObserverOnDealloc),
        ("testAddObserverMultipleTimes", testAddObserverMultipleTimes),
        ("testRemoveObserverMultipleTimes", testRemoveObserverMultipleTimes),
        ("testMultipleObserversForLifecycleOwner", testMultipleObserversForLifecycleOwner),
        ("testAddRemoveAddRemoveObserver", testAddRemoveAddRemoveObserver),
        ("testObserveDoesntFire", testObserveDoesntFire),
        ("testThreadSafety", testThreadSafety),
        ("testTrigger", testTrigger),
        ("testTriggerVoid", testTriggerVoid),
        ("testObserveAfterTrigger", testObserveAfterTrigger),
        ("testTriggerMultipleTimes", testTriggerMultipleTimes),
        ("testQueueWhereValueIsDispatched", testQueueWhereValueIsDispatched),
    ]
}

private class Owner {}

extension SingleEvent {
    func contains(_ observer: Observer<DataType>) -> Bool {
        return observers.lazy.filter { $0.observer == observer }.first != nil
    }
}
