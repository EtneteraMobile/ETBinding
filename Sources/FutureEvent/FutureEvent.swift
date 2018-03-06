//
//  FutureEvent.swift
//
//  Created by Jan Čislinský on 05. 03. 2018.
//  Copyright © 2018 Etnetera. All rights reserved.
//

import Foundation

public class FutureEvent<Action>: Observable {
    public typealias DataType = Action

    // MARK: - Variables
    // MARK: internal

    var observers: Set<LifecycleBoundObserver<DataType>> = []
    var lock: NSRecursiveLock = NSRecursiveLock()
}

public extension FutureEvent {
    // MARK: - Observe

    @discardableResult func observe(owner: LifecycleOwner, onUpdate: @escaping (DataType) -> Void) -> Observer<DataType> {
        let wrapper = LifecycleBoundObserver(owner: owner, observer: Observer(update: onUpdate))
        return observe(wrapper)
    }

    func observe(owner: LifecycleOwner, observer: Observer<DataType>) {
        let wrapper = LifecycleBoundObserver(owner: owner, observer: observer)
        observe(wrapper)
    }

    func observeForever(onUpdate: @escaping (DataType) -> Void) -> Observer<DataType> {
        let wrapper = LifecycleBoundObserver(observer: Observer(update: onUpdate))
        return observe(wrapper)
    }


    func observeForever(observer: Observer<DataType>) {
        let wrapper = LifecycleBoundObserver(observer: observer)
        observe(wrapper)
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
    @discardableResult func observe(_ wrapper: LifecycleBoundObserver<DataType>) -> Observer<DataType> {
        lock.lock()
        defer {
            lock.unlock()
        }
        guard observers.contains(wrapper) == false else {
            fatalError("Unable to register same observer multiple time")
        }
        observers.insert(wrapper)

        // Removes observer on owner dealloc
        if let owner = wrapper.owner {
            onDealloc(of: owner) { [weak self, weak wrapper] in
                if let wrapper = wrapper {
                    self?.remove(observer: wrapper.observer)
                }
            }
        }

        return wrapper.observer
    }
    
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
