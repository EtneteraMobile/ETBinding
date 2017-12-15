//
//  ObserverTests.swift
//  Etnetera
//
//  Created by Jan Cislinsky on 15. 12. 2017.
//  Copyright © 2017 Etnetera. All rights reserved.
//

import Foundation
import XCTest
import ETObserver

class ObserverTests: XCTestCase {
    func testTriggerSingleUpdate() {
        let update = "test"
        let expec = expectation(description: "Trigger")
        let observer = Observer { (input: String) in
            XCTAssert(input == update, "Updated value is invalid")
            expec.fulfill()
        }
        observer.update(update)
        waitForExpectations(timeout: 1, handler: nil)
    }

    func testTriggerMultipleUpdates() {
        var observers: [Observer<String>] = []
        for idx in 0..<100 {
            let expec = expectation(description: "Trigger \(idx)")
            let observer = Observer { (input: String) in
                XCTAssert(input == "\(idx)", "Updated value is invalid")
                expec.fulfill()
            }
            observers.append(observer)
        }
        observers.enumerated().reversed().forEach { idx, observer in
            observer.update("\(idx)")
        }
        waitForExpectations(timeout: 5, handler: nil)
    }

    func testUniquenessOfHashValue() {
        var ids: Set<Int> = []
        for i in 0..<1000000 {
            let id = Observer<String>(update: {_ in}).hashValue
            XCTAssert(ids.insert(id).inserted, "Duplicated hashValue of \(i). observer")
        }
    }

    func testEquatable() {
        let update: (String) -> Void = { input in
            print(input)
        }
        let o1 = Observer(update: update)
        var o2 = Observer(update: update)

        XCTAssert(o1 != o2, "Observers with same update closure don't have to equal")

        o2 = Observer(update: { _ in })

        XCTAssert(o1 != o2, "Observers with different update closure don't have to equal")
    }
    
    static var allTests = [
        ("testTriggerSingleUpdate", testTriggerSingleUpdate),
        ("testTriggerMultipleUpdates", testTriggerMultipleUpdates),
        ("testUniquenessOfHashValue", testUniquenessOfHashValue),
        ("testEquatable", testEquatable),
    ]
}
