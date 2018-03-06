//
//  SingleEvent.swift
//
//  Created by Jan Čislinský on 05. 03. 2018.
//  Copyright © 2018 Etnetera. All rights reserved.
//

import Foundation

public class SingleEvent<Action>: SingleEventObservable {
    public typealias DataType = Action

    // MARK: - Variables
    // MARK: internal

    var observers: Set<LifecycleBoundObserver<DataType>> = []
    var lock: NSRecursiveLock = NSRecursiveLock()

    // MARK: private

    fileprivate var triggered = false
}

public extension SingleEvent {
    // MARK: - Observe

    @discardableResult func observeSingleEvent(owner: LifecycleOwner, onUpdate: @escaping (DataType) -> Void) -> Observer<DataType> {
        return observe(owner, Observer(update: onUpdate))
    }

    func observeSingleEvent(owner: LifecycleOwner, observer: Observer<DataType>) {
        observe(owner, observer)
    }

    func observeSingleEventForever(onUpdate: @escaping (DataType) -> Void) -> Observer<DataType> {
        return observe(nil, Observer(update: onUpdate))
    }


    func observeSingleEventForever(observer: Observer<DataType>) {
        observe(nil, observer)
    }

    // MARK: - Remove

    @discardableResult func remove(observer: Observer<DataType>) -> Bool {
        lock.lock()
        defer {
            lock.unlock()
        }
        let existingIdx = observers.index { (rhs) -> Bool in
            observer.hashValue == rhs.observer.hashValue
        }
        if let idx = existingIdx {
            observers.remove(at: idx)
            return true
        }
        return false
    }
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
    @discardableResult func observe(_ owner: LifecycleOwner?, _ observer: Observer<DataType>) -> Observer<DataType> {
        lock.lock()
        defer {
            lock.unlock()
        }

        if triggered {
            fatalError("Unable to observe SingleEvent thas was already triggered.")
        }

        let existingIdx = observers.index { (rhs) -> Bool in
            observer.hashValue == rhs.observer.hashValue
        }
        guard existingIdx == nil else {
            fatalError("Unable to register same observer multiple time")
        }

        weak var weakOnceObserver: Observer<DataType>?
        let onceObserver: Observer<DataType> = Observer(identity: observer.hashValue) { [unowned self] data in
            if let onceObserver = weakOnceObserver {
                self.remove(observer: onceObserver)
            }
            observer.update(data)
        }
        weakOnceObserver = onceObserver

        let wrapper = LifecycleBoundObserver(owner: owner, observer: onceObserver)
        observers.insert(wrapper)

        // Removes observer on owner dealloc
        if let owner = wrapper.owner {
            onDealloc(of: owner) { [weak self, unowned wrapper] in
                self?.remove(observer: wrapper.observer)
            }
        }

        return wrapper.observer
    }

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
