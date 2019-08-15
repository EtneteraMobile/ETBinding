//
//  LiveOptionalStateDataTests.swift
//
//  Created by Jan Cislinsky on 15. 12. 2017.
//  Copyright © 2017 ETBinding. All rights reserved.
//

import Foundation
import XCTest
import ETBinding

class LiveOptionalStateDataTests: XCTestCase {

    var expectations: [XCTestExpectation]!
    var liveData: LiveOptionalStateData<String>!

    override func setUp() {
        super.setUp()
        liveData = LiveOptionalStateData<String>()
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

        waitForExpectations(timeout: 10, handler: nil)
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

        waitForExpectations(timeout: 10, handler: nil)

    }

        static var allTests = [
            ("testFailureState", testFailureState),
            ("testSuccessState", testSuccessState),
        ]
}

enum TestError: Swift.Error {
    case test
}

