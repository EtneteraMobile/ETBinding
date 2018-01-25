//
//  LiveStateDataTests.swift
//  ETLiveData
//
//  Created by Jan Cislinsky on 15. 12. 2017.
//  Copyright © 2017 ETLiveData. All rights reserved.
//

import Foundation
import XCTest
import ETObserver
import ETLiveData

class LiveStateDataTests: XCTestCase {

    var expectations: [XCTestExpectation]!
    var liveData: LiveStateData<String>!

    override func setUp() {
        super.setUp()
        liveData = LiveStateData<String>()
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

    func testSuccessState() {
        let str = "New data"
        let exp = expectation(description: str)
        let observer = Observer<StateValue<String>?>(update: { data in
            XCTAssertNotNil(data)
            if case .success(let value) = data! {
                XCTAssert(value == str)
            } else {
                XCTFail()
            }
            exp.fulfill()
        })

        liveData.observeForever(observer: observer)
        liveData.data = .success(str)

        waitForExpectations(timeout: 1, handler: nil)
    }

    func testFailureState() {
        let str = "New data"
        let exp = expectation(description: str)
        let observer = Observer<StateValue<String>?>(update: { data in
            XCTAssertNotNil(data)
            if case .failure(let error) = data! {
                if let err = error as? TestError {
                    XCTAssert(err == .test)
                } else {
                    XCTFail()
                }
            } else {
                XCTFail()
            }
            exp.fulfill()
        })

        liveData.observeForever(observer: observer)
        liveData.data = .failure(TestError.test)

        waitForExpectations(timeout: 1, handler: nil)

    }

        static var allTests = [
            ("testFailureState", testFailureState),
            ("testSuccessState", testSuccessState),
        ]
}

enum TestError: Swift.Error {
    case test
}

