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
import ETLiveData

class LiveDataTests: XCTestCase {

    func testObserveForever() {
        let data = "test"
        let exp = expectation(description: "New data")

        let observer = Observer<String?> { input in
            XCTAssert(input == data, "Observer returns invalid data")
            exp.fulfill()
        }

        let liveData = LiveData<String>()
        liveData.observeForever(observer: observer)
        liveData.dispatch()

        waitForExpectations(timeout: 1, handler: nil)
    }

    func testObserverWithLifecycleOwner() {

    }

    func testRemoveObserver() {
        
    }

    func testReadData() {

    }

    func testDispatchSameDataMultipleTimes() {

    }

    func testThreadInObserverUpdate() {

    }

    func testThreadSafety() {
        
    }
    
//    static var allTests = [
//        ("testExample", testExample),
//    ]
}
