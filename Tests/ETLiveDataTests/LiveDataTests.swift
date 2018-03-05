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
    private var liveData: LiveData<String>!

    override func setUp() {
        super.setUp()
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

        waitForExpectations(timeout: 1, handler: nil)
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

    static var allTests = [
        ("testReadData", testReadData),
        ("testStartObservingExistingDataAndDispatch", testStartObservingExistingDataAndDispatch),
        ("testDispatchSameDataMultipleTimes", testDispatchSameDataMultipleTimes),
        ("testDispatchToInitiator", testDispatchToInitiator),
        ("testDispatchToUnregisteredInitiator", testDispatchToUnregisteredInitiator),
        ("testQueueWhereValueIsDispatched", testQueueWhereValueIsDispatched),
        ]
}

private class Owner {}
