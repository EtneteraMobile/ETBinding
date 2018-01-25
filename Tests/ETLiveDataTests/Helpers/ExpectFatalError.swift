//
//  ExpectFatalError.swift
//  ETLiveData
//
//  Created by Jan Čislinský on 19. 12. 2017.
//  Copyright © 2017 ETLiveData. All rights reserved.
//

import Foundation
import XCTest
import ETLiveData

// source: https://stackoverflow.com/a/44140448/3475253

extension XCTestCase {
    func expectFatalError(withMessage message: String, testcase: @escaping () -> Void) {

        // arrange
        let expectation = self.expectation(description: "expectingFatalError")
        var assertionMessage: String? = nil

        // override fatalError. This will pause forever when fatalError is called.
        FatalErrorUtil.replaceFatalError { message, _, _ in
            assertionMessage = message
            expectation.fulfill()
            unreachable()
        }

        // act, perform on separate thead because a call to fatalError pauses forever
        DispatchQueue.global(qos: .userInitiated).async(execute: testcase)

        waitForExpectations(timeout: 0.1) { _ in
            // assert
            XCTAssert(assertionMessage == message, "Expected fatal error did not occurred (\(message)")

            // clean up
            FatalErrorUtil.restoreFatalError()
        }
    }
}
