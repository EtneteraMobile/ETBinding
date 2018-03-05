//
//  LiveDataTests.swift
//
//  Created by Jan Cislinsky on 15. 12. 2017.
//  Copyright © 2017 ETBinding. All rights reserved.
//

import Foundation
import XCTest
@testable import ETBinding

class ObservableTests: XCTestCase {

    private var owner: LifecycleOwner? = Owner()
    private var observable: ObservableClass!

    override func setUp() {
        super.setUp()
        owner = Owner()
        observable = ObservableClass()
    }

    func onUpdate(_ input: String) {}

    // MARK: -

    func testObserveWithObserverAndLifecycleOwner() {
        let observer = Observer<String>(update: onUpdate)
        observable.observe(owner: owner!, observer: observer)
        XCTAssert(observable.observers.count == 1)
        XCTAssert(observable.contains(observer))
    }

    func testObserveWithOnUpdateAndLifecycleOwner() {
        let observer = observable.observe(owner: owner!, onUpdate: onUpdate)
        XCTAssertNotNil(observer)
        XCTAssert(observable.observers.count == 1)
        XCTAssert(observable.contains(observer))
    }

    func testObserveForeverWithObserver() {
        let observer = Observer<String>(update: onUpdate)
        observable.observeForever(observer: observer)
        XCTAssert(observable.observers.count == 1)
        XCTAssert(observable.contains(observer))
    }

    func testObserveForeverWithOnUpdate() {
        let observer = observable.observeForever(onUpdate: onUpdate)
        XCTAssert(observable.observers.count == 1)
        XCTAssert(observable.contains(observer))
    }

    func testRemoveObserver() {
        let observer1 = Observer<String>(update: onUpdate)
        let observer2 = Observer<String>(update: onUpdate)

        observable.observeForever(observer: observer1)
        XCTAssert(observable.observers.count == 1)

        observable.observeForever(observer: observer2)
        XCTAssert(observable.observers.count == 2)

        XCTAssert(observable.contains(observer1))
        XCTAssert(observable.contains(observer2))

        observable.remove(observer: observer1)
        XCTAssert(observable.observers.count == 1)
        XCTAssertFalse(observable.contains(observer1))
        XCTAssert(observable.contains(observer2))

        observable.remove(observer: observer2)
        XCTAssert(observable.observers.isEmpty)
    }

    func testRemoveObserverOnDealloc() {
        let observer = observable.observe(owner: owner!, onUpdate: onUpdate)
        XCTAssertNotNil(observer)
        XCTAssert(observable.observers.count == 1)
        XCTAssert(observable.contains(observer))

        // Deallocs owner
        owner = nil

        XCTAssertFalse(observable.remove(observer: observer))
        XCTAssert(observable.observers.isEmpty)
        XCTAssertFalse(observable.contains(observer))
    }

    func testAddObserverMultipleTimes() {
        let observer = Observer<String>(update: onUpdate)
        expectFatalError(withMessage: "Unable to register same observer multiple time") {
            self.observable.observeForever(observer: observer)
            self.observable.observeForever(observer: observer)
        }
    }

    func testRemoveObserverMultipleTimes() {
        let observer = Observer<String>(update: onUpdate)
        self.observable.observeForever(observer: observer)
        XCTAssertTrue(observable.remove(observer: observer))
        XCTAssertFalse(observable.remove(observer: observer))
    }

    func testAddRemoveAddRemoveObserver() {
        let observer = Observer<String>(update: onUpdate)

        observable.observeForever(observer: observer)

        XCTAssert(observable.contains(observer))
        XCTAssertTrue(observable.remove(observer: observer))
        XCTAssertFalse(observable.contains(observer))

        observable.observeForever(observer: observer)

        XCTAssert(observable.contains(observer))
        XCTAssertTrue(observable.remove(observer: observer))
        XCTAssertFalse(observable.contains(observer))
        XCTAssertFalse(observable.remove(observer: observer))
        XCTAssert(observable.observers.isEmpty)
    }

    func testObserveDoesntFire() {
        var wasCalled = false
        _ = observable.observeForever(onUpdate: { input in
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
                self.observable.observeForever(observer: observer)
                DispatchQueue.global().async {
                    self.observable.remove(observer: observer)
                    exp.fulfill()
                }
            }
        }

        waitForExpectations(timeout: 10) { error in
            XCTAssert(self.observable.observers.isEmpty)
            XCTAssert(self.observable.observers.isEmpty, "Observers still registered")
        }
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
        ("testAddRemoveAddRemoveObserver", testAddRemoveAddRemoveObserver),
        ("testObserveDoesntFire", testObserveDoesntFire),
        ("testThreadSafety", testThreadSafety),
    ]
}

private class Owner {}

private class ObservableClass: Observable {
    typealias DataType = String
}
