//
//  PerformanceTests.swift
//  ETBinding-iOS Tests
//
//  Created by Jan Čislinský on 06. 03. 2018.
//  Copyright © 2018 Etnetera. All rights reserved.
//

import XCTest
import ETBinding

class PerformanceTests: XCTestCase {
    private var owner: LifecycleOwner? = Owner()
    private var observable: LiveData<String>!

    override func setUp() {
        super.setUp()
        owner = Owner()
        observable = LiveData()
    }
    
    func onUpdate(_ input: String?) {}
    
    func testPerformanceExample() {
        self.measure {
            let queue = DispatchQueue(label: "tests", qos: .userInitiated, attributes: .concurrent)
            let group = DispatchGroup()

            for _ in 0..<10000 {
                group.enter()
                let observer = Observer(update: self.onUpdate)
                let add = DispatchWorkItem(block: {
                    self.observable.observe(owner: self.owner!, observer: observer)
                })
                let remove = DispatchWorkItem(block: {
                    add.wait()
                    self.observable.remove(observer: observer)
                    group.leave()
                })

                queue.async(execute: add)
                queue.async(execute: remove)
            }

            group.wait()
        }
    }
}

private class Owner {}
