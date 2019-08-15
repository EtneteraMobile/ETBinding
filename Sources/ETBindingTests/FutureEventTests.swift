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
    private var owner: Owner!
    private var futureEvent: FutureEvent<String>!
    private var futureEventVoid: FutureEvent<Void>!

    override func setUp() {
        super.setUp()
        owner = Owner()
        futureEvent = FutureEvent<String>()
        futureEventVoid = FutureEvent<Void>()
    }

    func onUpdate(_ input: String) {
        update(input)
    }

    func update(_ input: String) {
        XCTAssertTrue(Thread.isMainThread)
        guard expectations.isEmpty == false else {
            XCTAssert(expectations.isEmpty == false, "Update called more than expected")
            return
        }
        XCTAssert(input == expectations[0].expectationDescription, "Observer receives invalid data")
        expectations[0].fulfill()
        expectations.removeFirst()
    }

    // MARK: - Observable tests

    func testObserveWithObserverAndLifecycleOwner() {
        let observer = Observer(update: onUpdate)
        futureEvent.observe(owner: owner!, observer: observer)
        XCTAssert(futureEvent.observers.count == 1)
        XCTAssert(futureEvent.contains(observer))
    }

    func testObserveWithOnUpdateAndLifecycleOwner() {
        let observer = futureEvent.observe(owner: owner!, onUpdate: onUpdate)
        XCTAssertNotNil(observer)
        XCTAssert(futureEvent.observers.count == 1)
        XCTAssert(futureEvent.contains(observer))
    }

    func testObserveForeverWithObserver() {
        let observer = Observer(update: onUpdate)
        futureEvent.observeForever(observer: observer)
        XCTAssert(futureEvent.observers.count == 1)
        XCTAssert(futureEvent.contains(observer))
    }

    func testObserveForeverWithOnUpdate() {
        let observer = futureEvent.observeForever(onUpdate: onUpdate)
        XCTAssert(futureEvent.observers.count == 1)
        XCTAssert(futureEvent.contains(observer))
    }

    func testRemoveObserver() {
        let observer1 = Observer(update: onUpdate)
        let observer2 = Observer(update: onUpdate)

        futureEvent.observeForever(observer: observer1)
        XCTAssert(futureEvent.observers.count == 1)

        futureEvent.observeForever(observer: observer2)
        XCTAssert(futureEvent.observers.count == 2)

        XCTAssert(futureEvent.contains(observer1))
        XCTAssert(futureEvent.contains(observer2))

        futureEvent.remove(observer: observer1)
        XCTAssert(futureEvent.observers.count == 1)
        XCTAssertFalse(futureEvent.contains(observer1))
        XCTAssert(futureEvent.contains(observer2))

        futureEvent.remove(observer: observer2)
        XCTAssert(futureEvent.observers.isEmpty)
    }

    func testRemoveObserverOnDealloc() {
        let observer = futureEvent.observe(owner: owner!, onUpdate: onUpdate)
        XCTAssertNotNil(observer)
        XCTAssert(futureEvent.observers.count == 1)
        XCTAssert(futureEvent.contains(observer))

        // Deallocs owner
        owner = nil

        XCTAssertFalse(futureEvent.remove(observer: observer))
        XCTAssert(futureEvent.observers.isEmpty)
        XCTAssertFalse(futureEvent.contains(observer))
    }

    func testMultipleObserversForLifecycleOwner() {
        let numberOfObservers = 1000
        let observers = Array(1...numberOfObservers).map { (counter) -> (Observer<String>) in
            let observer = futureEvent.observe(owner: owner!, onUpdate: onUpdate)
            XCTAssert(futureEvent.observers.count == counter)
            XCTAssertNotNil(observer)
            XCTAssert(futureEvent.contains(observer))
            return observer
        }

        // Deallocs owner
        owner = nil

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            observers.forEach {
                XCTAssertFalse(self.futureEvent.contains($0))
                XCTAssertFalse(self.futureEvent.remove(observer: $0))
            }

            XCTAssert(self.futureEvent.observers.isEmpty)
        }
    }

    func testRemoveObserverMultipleTimes() {
        let observer = Observer(update: onUpdate)
        self.futureEvent.observeForever(observer: observer)
        XCTAssertTrue(futureEvent.remove(observer: observer))
        XCTAssertFalse(futureEvent.remove(observer: observer))
    }

    func testAddRemoveAddRemoveObserver() {
        let observer = Observer(update: onUpdate)

        futureEvent.observeForever(observer: observer)

        XCTAssert(futureEvent.contains(observer))
        XCTAssertTrue(futureEvent.remove(observer: observer))
        XCTAssertFalse(futureEvent.contains(observer))

        futureEvent.observeForever(observer: observer)

        XCTAssert(futureEvent.contains(observer))
        XCTAssertTrue(futureEvent.remove(observer: observer))
        XCTAssertFalse(futureEvent.contains(observer))
        XCTAssertFalse(futureEvent.remove(observer: observer))
        XCTAssert(futureEvent.observers.isEmpty)
    }

    func testObserveDoesntFire() {
        var wasCalled = false
        _ = futureEvent.observeForever(onUpdate: { input in
            wasCalled = true
        })
        XCTAssertFalse(wasCalled)
    }

    func testThreadSafety() {
        let cycles = 1000

        for i in 1...cycles {
            let exp = expectation(description: "New data \(i)")
            let observer = Observer(update: onUpdate)
            DispatchQueue.global().async {
                self.futureEvent.observeForever(observer: observer)
                DispatchQueue.global().async {
                    self.futureEvent.remove(observer: observer)
                    exp.fulfill()
                }
            }
        }

        waitForExpectations(timeout: 10) { error in
            XCTAssert(self.futureEvent.observers.isEmpty)
            XCTAssert(self.futureEvent.observers.isEmpty, "Observers still registered")
        }
    }

    // MARK: - Future event tests

    func testTrigger() {
        expectations = [expectation(description: "New data 1")]

        _ = futureEvent.observeForever(onUpdate: onUpdate)
        futureEvent.trigger(expectations[0].expectationDescription)

        waitForExpectations(timeout: 10, handler: nil)
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

        waitForExpectations(timeout: 10, handler: nil)
    }

    func testIsOnMainThreadInObserveClosureWhenTriggerFromGlobalQueue() {
        expectations = [expectation(description: "New data 1")]

        futureEvent.observeForever { input in
            XCTAssertTrue(Thread.isMainThread)
            self.expectations[0].fulfill()
        }
        DispatchQueue.global().async {
            self.futureEvent.trigger(self.expectations[0].expectationDescription)
        }
        waitForExpectations(timeout: 1, handler: nil)
    }

    func testMainThreadIsntBlockedWhenEnterItSynchronousllyInObserveClosure() {
        expectations = [expectation(description: "New data 1"), expectation(description: "New data 2"), expectation(description: "New data 3"), expectation(description: "New data 4"), expectation(description: "New data 5"), expectation(description: "New data 6"), expectation(description: "New data 7"), expectation(description: "New data 8"), expectation(description: "New data 9"), expectation(description: "New data 10")]

        futureEvent.observeForever { input in
            func test() {
                self.expectations.first!.fulfill()
                self.expectations.removeFirst()
            }
            // Note: always on Main but developer couldn't know
            if Thread.isMainThread {
                test()
            } else {
                DispatchQueue.main.sync(execute: test)
            }
        }
        let exp1 = expectations[0]
        DispatchQueue.global().async {
            self.futureEvent.trigger(exp1.expectationDescription)
        }
        for _ in 0..<9 {
            self.futureEvent.trigger("doesn't matter")
        }
        waitForExpectations(timeout: 2, handler: nil)
    }

    static var allTests = [
        ("testObserveWithObserverAndLifecycleOwner", testObserveWithObserverAndLifecycleOwner),
        ("testObserveWithOnUpdateAndLifecycleOwner", testObserveWithOnUpdateAndLifecycleOwner),
        ("testObserveForeverWithObserver", testObserveForeverWithObserver),
        ("testObserveForeverWithOnUpdate", testObserveForeverWithOnUpdate),
        ("testRemoveObserver", testRemoveObserver),
        ("testRemoveObserverOnDealloc", testRemoveObserverOnDealloc),
        ("testRemoveObserverMultipleTimes", testRemoveObserverMultipleTimes),
        ("testMultipleObserversForLifecycleOwner", testMultipleObserversForLifecycleOwner),
        ("testAddRemoveAddRemoveObserver", testAddRemoveAddRemoveObserver),
        ("testObserveDoesntFire", testObserveDoesntFire),
        ("testThreadSafety", testThreadSafety),
        ("testTrigger", testTrigger),
        ("testTriggerVoid", testTriggerVoid),
        ("testTriggerMultipleTimes", testTriggerMultipleTimes),
        ("testIsOnMainThreadInObserveClosureWhenTriggerFromGlobalQueue", testIsOnMainThreadInObserveClosureWhenTriggerFromGlobalQueue),
        ("testMainThreadIsntBlockedWhenEnterItSynchronousllyInObserveClosure", testMainThreadIsntBlockedWhenEnterItSynchronousllyInObserveClosure),
    ]
}

private class Owner {}

extension FutureEvent {
    func contains(_ observer: Observer<DataType>) -> Bool {
        return observers.lazy.filter { $0.observer == observer }.first != nil
    }
}

