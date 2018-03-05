//
//  FutureEvent.swift
//
//  Created by Jan Čislinský on 05. 03. 2018.
//  Copyright © 2018 Etnetera. All rights reserved.
//

import Foundation

public class FutureEvent<Action>: Observable {
    public typealias DataType = Action
}

public extension FutureEvent where DataType == Void {
    public func trigger() {
        triggerObservers(())
    }
}

public extension FutureEvent where DataType: Any {
    public func trigger(_ arg: DataType) {
        triggerObservers(arg)
    }
}

private extension FutureEvent {
    func triggerObservers(_ arg: DataType) {
        lock.lock()
        defer {
            lock.unlock()
        }
        // Removes destroyed observers
        observers = observers.filter {
            $0.state != .destroyed
        }
        // Triggers all observers
        observers.forEach {
            $0.observer.update(arg)
        }
    }
}
