//
//  ExpectQueue.swift
//  ETBinding
//
//  Created by Jan Čislinský on 20. 12. 2017.
//  Copyright © 2017 ETBinding. All rights reserved.
//

import Foundation
import XCTest

extension XCTestCase {
    func makeQueueWithKey() -> (DispatchSpecificKey<Void>, DispatchQueue) {
        let testQueueLabel = "cz.etnetera.livedata-test-queue"
        let testQueue = DispatchQueue(label: testQueueLabel, attributes: [])
        let testQueueKey = DispatchSpecificKey<Void>()

        testQueue.setSpecific(key: testQueueKey, value: ())

        return (testQueueKey, testQueue)
    }

    func expectQueue(withKey key: DispatchSpecificKey<Void>) {
        XCTAssertNotNil(DispatchQueue.getSpecific(key: key), "Invalid queue, specific is missing.")
    }
}
