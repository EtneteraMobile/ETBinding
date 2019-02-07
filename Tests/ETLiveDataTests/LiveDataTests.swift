//
//  LiveDataTests.swift
//
//  Created by Jan Cislinsky on 15. 12. 2017.
//  Copyright © 2017 ETLiveData. All rights reserved.
//

import Foundation
import XCTest
@testable import ETBinding

class LiveDataTests: XCTestCase {
    private var expectations: [XCTestExpectation]!
    private var owner: Owner!
    private var liveData: LiveData<String>!

    override func setUp() {
        super.setUp()
        owner = Owner()
        liveData = LiveData<String>()
    }

    func onUpdate(_ input: String?) {
        update(input)
    }

    func update(_ input: String?) {
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
        liveData.observe(owner: owner!, observer: observer)
        XCTAssert(liveData.observers.count == 1)
        XCTAssert(liveData.contains(observer))
    }

    func testObserveWithOnUpdateAndLifecycleOwner() {
        let observer = liveData.observe(owner: owner!, onUpdate: onUpdate)
        XCTAssertNotNil(observer)
        XCTAssert(liveData.observers.count == 1)
        XCTAssert(liveData.contains(observer))
    }

    func testObserveForeverWithObserver() {
        let observer = Observer(update: onUpdate)
        liveData.observeForever(observer: observer)
        XCTAssert(liveData.observers.count == 1)
        XCTAssert(liveData.contains(observer))
    }

    func testObserveForeverWithOnUpdate() {
        let observer = liveData.observeForever(onUpdate: onUpdate)
        XCTAssert(liveData.observers.count == 1)
        XCTAssert(liveData.contains(observer))
    }

    func testRemoveObserver() {
        let observer1 = Observer(update: onUpdate)
        let observer2 = Observer(update: onUpdate)

        liveData.observeForever(observer: observer1)
        XCTAssert(liveData.observers.count == 1)

        liveData.observeForever(observer: observer2)
        XCTAssert(liveData.observers.count == 2)

        XCTAssert(liveData.contains(observer1))
        XCTAssert(liveData.contains(observer2))

        liveData.remove(observer: observer1)
        XCTAssert(liveData.observers.count == 1)
        XCTAssertFalse(liveData.contains(observer1))
        XCTAssert(liveData.contains(observer2))

        liveData.remove(observer: observer2)
        XCTAssert(liveData.observers.isEmpty)
    }

    func testRemoveObserverOnDealloc() {
        let observer = liveData.observe(owner: owner!, onUpdate: onUpdate)
        XCTAssertNotNil(observer)
        XCTAssert(liveData.observers.count == 1)
        XCTAssert(liveData.contains(observer))

        // Deallocs owner
        owner = nil

        XCTAssertFalse(liveData.contains(observer))
        XCTAssert(liveData.observers.isEmpty)
        XCTAssertFalse(liveData.remove(observer: observer))
    }

    func testMultipleObserversForLifecycleOwner() {
        let numberOfObservers = 1000
        let observers = Array(1...numberOfObservers).map { (counter) -> (Observer<String?>) in
            let observer = liveData.observe(owner: owner!, onUpdate: onUpdate)
            XCTAssert(liveData.observers.count == counter)
            XCTAssertNotNil(observer)
            XCTAssert(liveData.contains(observer))
            return observer
        }

        // Deallocs owner
        owner = nil

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            observers.forEach {
                XCTAssertFalse(self.liveData.contains($0))
                XCTAssertFalse(self.liveData.remove(observer: $0))
            }

            XCTAssert(self.liveData.observers.isEmpty)
        }
    }

    func testRemoveObserverMultipleTimes() {
        let observer = Observer(update: onUpdate)
        self.liveData.observeForever(observer: observer)
        XCTAssertTrue(liveData.remove(observer: observer))
        XCTAssertFalse(liveData.remove(observer: observer))
    }

    func testAddRemoveAddRemoveObserver() {
        let observer = Observer(update: onUpdate)

        liveData.observeForever(observer: observer)

        XCTAssert(liveData.contains(observer))
        XCTAssertTrue(liveData.remove(observer: observer))
        XCTAssertFalse(liveData.contains(observer))

        liveData.observeForever(observer: observer)

        XCTAssert(liveData.contains(observer))
        XCTAssertTrue(liveData.remove(observer: observer))
        XCTAssertFalse(liveData.contains(observer))
        XCTAssertFalse(liveData.remove(observer: observer))
        XCTAssert(liveData.observers.isEmpty)
    }

    func testObserveDoesntFire() {
        var wasCalled = false
        _ = liveData.observeForever(onUpdate: { input in
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
                self.liveData.observeForever(observer: observer)
                DispatchQueue.global().async {
                    self.liveData.remove(observer: observer)
                    exp.fulfill()
                }
            }
        }

        waitForExpectations(timeout: 10) { error in
            XCTAssert(self.liveData.observers.isEmpty)
            XCTAssert(self.liveData.observers.isEmpty, "Observers still registered")
        }
    }

    // MARK: - Live data tests

    func testReadData() {
        let data1 = "test1"
        let data2 = "test2"

        XCTAssertNil(liveData.data)
        liveData.data = data1
        XCTAssertNotNil(liveData.data)
        XCTAssert(liveData.data! == data1, "Data not equal")

        liveData.data = data2
        XCTAssertNotNil(liveData.data)
        XCTAssert(liveData.data! == data2, "Data not equal")

        liveData.data = nil
        XCTAssertNil(liveData.data)
    }

    func testDispatchAfterDataAssignment() {
        expectations = [expectation(description: "New data 1")]

        _ = liveData.observeForever(onUpdate: onUpdate)
        liveData.data = expectations[0].expectationDescription

        waitForExpectations(timeout: 10, handler: nil)
    }

    func testStartObservingExistingDataAndDispatch() {
        expectations = [expectation(description: "New data 1")]

        liveData.data = expectations[0].expectationDescription

        _ = liveData.observeForever(onUpdate: onUpdate)
        liveData.dispatch()

        waitForExpectations(timeout: 10, handler: nil)
    }

    func testDispatchSameDataMultipleTimes() {
        expectations = [expectation(description: "New data 1")]

        liveData.data = expectations[0].expectationDescription

        _ = liveData.observeForever(onUpdate: onUpdate)
        liveData.dispatch()
        liveData.dispatch()

        waitForExpectations(timeout: 10, handler: nil)
    }

    func testDispatchToInitiator() {
        expectations = [expectation(description: "New data 1")]
        let observer1 = Observer(update: onUpdate)
        let observer2 = Observer(update: onUpdate)

        liveData.data = expectations[0].expectationDescription
        liveData.observeForever(observer: observer1)
        liveData.observeForever(observer: observer2)

        liveData.dispatch(initiator: observer1)

        waitForExpectations(timeout: 10, handler: nil)
    }

    func testIsOnMainThreadInObserveClosureWhenTriggerFromGlobalQueue() {
        expectations = [expectation(description: "New data 1")]

        liveData.observeForever { input in
            XCTAssertTrue(Thread.isMainThread)
            self.expectations[0].fulfill()
        }
        DispatchQueue.global().async {
            self.liveData.data = self.expectations[0].expectationDescription
        }
        waitForExpectations(timeout: 1, handler: nil)
    }

    func testMainThreadIsntBlockedWhenEnterItSynchronousllyInObserveClosure() {
        expectations = [expectation(description: "New data 1"), expectation(description: "New data 2")]

        liveData.observeForever { input in
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
        let exp2 = expectations[1]
        DispatchQueue.global().async {
            self.liveData.data = exp1.expectationDescription
        }
        self.liveData.data = exp2.expectationDescription
        waitForExpectations(timeout: 2, handler: nil)
    }

    func testDispatchWhenInitWithData() {
        expectations = [expectation(description: "New data 1")]

        let liveData = LiveData(data: "doesn't matter")

        liveData.observeForever { input in
            self.expectations[0].fulfill()
        }
        liveData.dispatch()
        waitForExpectations(timeout: 1, handler: nil)
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
        ("testReadData", testReadData),
        ("testDispatchAfterDataAssignment", testDispatchAfterDataAssignment),
        ("testStartObservingExistingDataAndDispatch", testStartObservingExistingDataAndDispatch),
        ("testDispatchSameDataMultipleTimes", testDispatchSameDataMultipleTimes),
        ("testDispatchToInitiator", testDispatchToInitiator),
        ("testIsOnMainThreadInObserveClosureWhenTriggerFromGlobalQueue", testIsOnMainThreadInObserveClosureWhenTriggerFromGlobalQueue),
        ("testMainThreadIsntBlockedWhenEnterItSynchronousllyInObserveClosure", testMainThreadIsntBlockedWhenEnterItSynchronousllyInObserveClosure),
        ("testDispatchWhenInitWithData", testDispatchWhenInitWithData),
    ]
}

private class Owner {}

extension LiveData {
    func contains(_ observer: Observer<DataType>) -> Bool {
        return observers.lazy.filter { $0.observer == observer }.first != nil
    }
}
