//
//  LiveDataTests.swift
//  ETLiveData
//
//  Created by Jan Cislinsky on 15. 12. 2017.
//  Copyright © 2017 ETLiveData. All rights reserved.
//

import Foundation
import XCTest
import ETObserver
@testable import ETLiveData

class LiveDataTests: XCTestCase {

    var owner: LifecycleOwner? = Owner()
    var expectations: [XCTestExpectation]!
    var liveData: LiveData<String>!

    override func setUp() {
        super.setUp()
        owner = Owner()
        liveData = LiveData<String>()
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

    func testObserveForever() {
        expectations = [expectation(description: "New data 1"), expectation(description: "New data 2")]
        let observer = Observer<String?>(update: onUpdate)

        liveData.observeForever(observer: observer)

        let data1 = expectations[0].expectationDescription
        let data2 = expectations[1].expectationDescription

        liveData.data = data1
        liveData.data = data2

        waitForExpectations(timeout: 1, handler: nil)
    }

    func testObserveWithObserverAndLifecycleOwner() {
        expectations = [expectation(description: "New data 1"), expectation(description: "New data 2")]
        let observer = Observer<String?>(update: onUpdate)

        liveData.observe(owner: owner!, observer: observer)

        let data1 = expectations[0].expectationDescription
        let data2 = expectations[1].expectationDescription

        liveData.data = data1
        liveData.data = data2

        waitForExpectations(timeout: 1, handler: nil)
    }

    func testObserveWithOnUpdateAndLifecycleOwner() {
        expectations = [expectation(description: "New data 1"), expectation(description: "New data 2")]

        liveData.observe(owner: owner!, onUpdate: onUpdate)

        let data1 = expectations[0].expectationDescription
        let data2 = expectations[1].expectationDescription

        liveData.data = data1
        liveData.data = data2

        waitForExpectations(timeout: 1, handler: nil)
    }

    func testObserveSingleEventWithObserver() {
        expectations = [expectation(description: "New data 1")]
        let observer = Observer<String?>(update: onUpdate)

        XCTAssertTrue(liveData.observers.isEmpty)
        liveData.observeSingleEventForever(observer: observer)
        XCTAssertFalse(liveData.observers.isEmpty)

        liveData.data = expectations[0].expectationDescription
        XCTAssertTrue(liveData.observers.isEmpty)

        liveData.data = "without dispatch"

        waitForExpectations(timeout: 1, handler: nil)
    }

    func testObserveSingleEventWithOnUpdate() {
        expectations = [expectation(description: "New data 1")]

        XCTAssertTrue(liveData.observers.isEmpty)
        liveData.observeSingleEventForever(onUpdate: onUpdate)
        XCTAssertFalse(liveData.observers.isEmpty)

        liveData.data = expectations[0].expectationDescription
        XCTAssertTrue(liveData.observers.isEmpty)

        liveData.data = "without dispatch"

        waitForExpectations(timeout: 1, handler: nil)
    }

    func testObserveSingleEventWithObserverAndOwner_ownerDealloc() {
        let observer = Observer<String?>(update: onUpdate)

        XCTAssertTrue(liveData.observers.isEmpty)
        liveData.observeSingleEvent(owner: owner!, observer: observer)
        XCTAssertFalse(liveData.observers.isEmpty)

        owner = nil
        liveData.data = "without dispatch"
    }

    func testObserveSingleEventWithOnUpdateAndOwner_ownerDealloc() {
        XCTAssertTrue(liveData.observers.isEmpty)
        liveData.observeSingleEvent(owner: owner!, onUpdate: onUpdate)
        XCTAssertFalse(liveData.observers.isEmpty)

        owner = nil
        liveData.data = "without dispatch"
    }

    func testObserveSingleEventWithObserverAndOwner_removeAfterDispatch() {
        expectations = [expectation(description: "New data 1")]
        let observer = Observer<String?>(update: onUpdate)

        XCTAssertTrue(liveData.observers.isEmpty)
        liveData.observeSingleEvent(owner: owner!, observer: observer)
        XCTAssertFalse(liveData.observers.isEmpty)

        liveData.data = expectations[0].expectationDescription
        XCTAssertTrue(liveData.observers.isEmpty)

        liveData.data = "without dispatch"

        waitForExpectations(timeout: 1, handler: nil)
    }

    func testObserveSingleEventWithOnUpdateAndOwner_removeAfterDispatch() {
        expectations = [expectation(description: "New data 1")]

        XCTAssertTrue(liveData.observers.isEmpty)
        liveData.observeSingleEvent(owner: owner!, onUpdate: onUpdate)
        XCTAssertFalse(liveData.observers.isEmpty)

        liveData.data = expectations[0].expectationDescription
        XCTAssertTrue(liveData.observers.isEmpty)

        liveData.data = "without dispatch"

        waitForExpectations(timeout: 1, handler: nil)
    }

    func testRemoveObserver() {
        expectations = [expectation(description: "New data 1")]
        let observer1 = Observer<String?>(update: onUpdate)
        let observer2 = Observer<String?>(update: onUpdate)

        liveData.observeForever(observer: observer1)
        liveData.observeForever(observer: observer2)

        liveData.remove(observer: observer1)
        liveData.data = expectations[0].expectationDescription
        liveData.remove(observer: observer2)
        liveData.data = "without dispatch"

        waitForExpectations(timeout: 1, handler: nil)
    }

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

    func testObserveOnUpdateDoesntFire() {
        var wasCalled = false
        _ = liveData.observeForever(onUpdate: { input in
            wasCalled = true
        })
        XCTAssertFalse(wasCalled)
    }

    func testStartObservingExistingDataAndDispatch() {
        expectations = [expectation(description: "New data 1")]

        liveData.data = expectations[0].expectationDescription

        _ = liveData.observeForever(onUpdate: onUpdate)
        liveData.dispatch()

        waitForExpectations(timeout: 1, handler: nil)
    }

    func testDispatchSameDataMultipleTimes() {
        expectations = [expectation(description: "New data 1")]

        liveData.data = expectations[0].expectationDescription

        _ = liveData.observeForever(onUpdate: onUpdate)
        liveData.dispatch()
        liveData.dispatch()

        waitForExpectations(timeout: 1, handler: nil)
    }

    func testRemoveObserverOnDealloc() {
        expectations = [expectation(description: "New data 1")]
        let observer = Observer<String?>(update: onUpdate)

        liveData.observe(owner: owner!, observer: observer)
        liveData.data = expectations[0].expectationDescription

        // Deallocs owner
        owner = nil
        liveData.data = "without dispatch"

        waitForExpectations(timeout: 1, handler: nil)
    }

    func testDispatchToInitiator() {
        expectations = [expectation(description: "New data 1")]
        let observer1 = Observer<String?>(update: onUpdate)
        let observer2 = Observer<String?>(update: onUpdate)

        liveData.data = expectations[0].expectationDescription
        liveData.observeForever(observer: observer1)
        liveData.observeForever(observer: observer2)

        liveData.dispatch(initiator: observer1)

        waitForExpectations(timeout: 1, handler: nil)
    }

    func testDispatchToUnregisteredInitiator() {
        let observer1 = Observer<String?>(update: onUpdate)

        expectFatalError(withMessage: "Initiator was never registered for observation") {
            self.liveData.dispatch(initiator: observer1)
        }
    }

    func testAddObserverMultipleTimes() {
        let observer = Observer<String?>(update: onUpdate)
        expectFatalError(withMessage: "Unable to register same observer multiple time") {
            self.liveData.observeForever(observer: observer)
            self.liveData.observeForever(observer: observer)
        }
    }

    func testRemoveObserverMultipleTimes() {
        let observer = Observer<String?>(update: onUpdate)
        self.liveData.observeForever(observer: observer)
        XCTAssertTrue(liveData.remove(observer: observer))
        XCTAssertFalse(liveData.remove(observer: observer))
    }

    func testAddRemoveAddRemoveObserver() {
        expectations = [expectation(description: "New data 1"), expectation(description: "New data 2")]
        let observer = Observer<String?>(update: onUpdate)

        let data1 = expectations[0].expectationDescription
        let data2 = expectations[1].expectationDescription

        liveData.observeForever(observer: observer)
        liveData.data = data1
        XCTAssertTrue(liveData.remove(observer: observer))

        liveData.observeForever(observer: observer)
        liveData.data = data2
        XCTAssertTrue(liveData.remove(observer: observer))

        XCTAssertFalse(liveData.remove(observer: observer))

        waitForExpectations(timeout: 1, handler: nil)
    }

    func testQueueWhereValueIsDispatched() {
        expectations = [expectation(description: "New data 1")]
        let queue = makeQueueWithKey()
        let observer = Observer<String?>(update: curry(onUpdate)(queue.0))
        
        liveData.observeForever(observer: observer)
        queue.1.sync {
            liveData.data = expectations[0].expectationDescription
        }

        waitForExpectations(timeout: 1, handler: nil)
    }

    func testThreadSafety() {
        let cycles = 1000

        for i in 1...cycles {
            let exp = expectation(description: "New data \(i)")
            let observer = Observer<String?>(update: onUpdate)
            DispatchQueue.global().async {
                self.liveData.observeForever(observer: observer)
                DispatchQueue.global().async {
                    self.liveData.remove(observer: observer)
                    exp.fulfill()
                }
            }
        }

        waitForExpectations(timeout: 10) { error in
            self.liveData.data = "without dispatch"
            XCTAssert(self.liveData.observers.isEmpty, "Observers still registered")
        }
    }
    
    static var allTests = [
        ("testObserveForever", testObserveForever),
        ("testObserveWithObserverAndLifecycleOwner", testObserveWithObserverAndLifecycleOwner),
        ("testObserveWithOnUpdateAndLifecycleOwner", testObserveWithOnUpdateAndLifecycleOwner),
        ("testObserveSingleEventWithObserver", testObserveSingleEventWithObserver),
        ("testObserveSingleEventWithOnUpdate", testObserveSingleEventWithOnUpdate),
        ("testObserveSingleEventWithObserverAndOwner_ownerDealloc", testObserveSingleEventWithObserverAndOwner_ownerDealloc),
        ("testObserveSingleEventWithOnUpdateAndOwner_ownerDealloc", testObserveSingleEventWithOnUpdateAndOwner_ownerDealloc),
        ("testObserveSingleEventWithObserverAndOwner_removeAfterDispatch", testObserveSingleEventWithObserverAndOwner_removeAfterDispatch),
        ("testObserveSingleEventWithOnUpdateAndOwner_removeAfterDispatch", testObserveSingleEventWithOnUpdateAndOwner_removeAfterDispatch),
        ("testRemoveObserver", testRemoveObserver),
        ("testReadData", testReadData),
        ("testObserveOnUpdateDoesntFire", testObserveOnUpdateDoesntFire),
        ("testStartObservingExistingDataAndDispatch", testStartObservingExistingDataAndDispatch),
        ("testDispatchSameDataMultipleTimes", testDispatchSameDataMultipleTimes),
        ("testRemoveObserverOnDealloc", testRemoveObserverOnDealloc),
        ("testDispatchToInitiator", testDispatchToInitiator),
        ("testDispatchToUnregisteredInitiator", testDispatchToUnregisteredInitiator),
        ("testAddObserverMultipleTimes", testAddObserverMultipleTimes),
        ("testRemoveObserverMultipleTimes", testRemoveObserverMultipleTimes),
        ("testAddRemoveAddRemoveObserver", testAddRemoveAddRemoveObserver),
        ("testQueueWhereValueIsDispatched", testQueueWhereValueIsDispatched),
        ("testThreadSafety", testThreadSafety),
    ]
}

class Owner {}
