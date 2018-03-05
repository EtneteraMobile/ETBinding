//
//  SingleEvent.swift
//
//  Created by Jan Čislinský on 05. 03. 2018.
//  Copyright © 2018 Etnetera. All rights reserved.
//

import Foundation

public class SingleEvent<Action>: SingleEventObservable {
    public typealias DataType = Action

    fileprivate var triggered = false
}

public extension SingleEvent where DataType == Void {
    public func trigger() {
        triggerObservers(())
    }
}

public extension SingleEvent where DataType: Any {
    public func trigger(_ arg: DataType) {
        triggerObservers(arg)
    }
}

private extension SingleEvent {
    func triggerObservers(_ arg: DataType) {
        lock.lock()
        defer {
            lock.unlock()
        }

        if triggered {
            fatalError("Unable to trigger SingleEvent multiple times.")
        }

        // Removes destroyed observers
        observers = observers.filter {
            $0.state != .destroyed
        }
        // Triggers all observers
        observers.forEach {
            $0.observer.update(arg)
        }
        triggered = true
    }
}
