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

    func testObserveWithLifecycleOwner() {
        expectations = [expectation(description: "New data 1"), expectation(description: "New data 2")]
        let observer = Observer<String?>(update: onUpdate)

        liveData.observe(owner: owner!, observer: observer)

        let data1 = expectations[0].expectationDescription
        let data2 = expectations[1].expectationDescription

        liveData.data = data1
        liveData.data = data2

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

    func testObserverLifecycle() {
        expectations = [expectation(description: "New data 1")]
        let observer = Observer<String?>(update: onUpdate)

        liveData.observe(owner: owner!, observer: observer)
        liveData.data = expectations[0].expectationDescription

        // Deallocs owner
        owner = nil
        liveData.data = "without dispatch"

        waitForExpectations(timeout: 1, handler: nil)
    }

    func testDispatchWithInitiator() {
        expectations = [expectation(description: "New data 1")]
        let observer1 = Observer<String?>(update: onUpdate)
        let observer2 = Observer<String?>(update: onUpdate)

        liveData.data = expectations[0].expectationDescription
        liveData.observeForever(observer: observer1)
        liveData.observeForever(observer: observer2)

        liveData.dispatch(initiator: observer1)

        waitForExpectations(timeout: 1, handler: nil)
    }

    func testAddObserverMultipleTimes() {
        let observer = Observer<String?>(update: onUpdate)
        expectFatalError(expectedMessage: "Unable to register same observer multiple time") {
            self.liveData.observeForever(observer: observer)
            self.liveData.observeForever(observer: observer)
        }
    }

    func testRemoveMultipleObservers() {}
    func testThreadInObserverUpdate() {

    }

    func testThreadSafety() {

    }
    
//    static var allTests = [
//        ("testExample", testExample),
//    ]
}

class Owner: LifecycleOwner {
    func on(dealloc: @escaping () -> Void) {
        ETLiveData.onDealloc(of: self) {
            dealloc()
        }
    }
}
