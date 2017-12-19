//
//  LiveData.swift
//  ETLiveData
//
//  Created by Jan Čislinský on 15. 12. 2017.
//  Copyright © 2017 ETLiveData. All rights reserved.
//

import Foundation
import ETObserver

public class LiveData<Value> {
    // MARK: public
    public typealias DataType = Value?
    public var data: DataType {
        didSet {
            version += 1
            dispatch()
        }
    }
    // MARK: private
    private var version: Int = Constants.startVersion
    private var observers: Set<LifecycleBoundObserver<DataType>> = []

    // MARK: - Initialization

    public init(data: DataType = nil) {
        self.data = data
    }
}

// MARK: - Public

public extension LiveData {
    // MARK: - Observe

    @discardableResult func observe(owner: LifecycleOwner, onUpdate: @escaping (DataType) -> Void) -> Observer<DataType> {
        let wrapper = LifecycleBoundObserver(owner: owner, observer: Observer(update: onUpdate))
        return observe(wrapper)
    }

    @discardableResult func observe(owner: LifecycleOwner, observer: Observer<DataType>) -> Observer<DataType>? {
        let wrapper = LifecycleBoundObserver(owner: owner, observer: observer)
        return observe(wrapper)
    }

    func observeForever(onUpdate: @escaping (DataType) -> Void) -> Observer<DataType> {
        let wrapper = LifecycleBoundObserver(observer: Observer(update: onUpdate))
        return observe(wrapper)
    }

    @discardableResult func observeForever(observer: Observer<DataType>) -> Observer<DataType>? {
        let wrapper = LifecycleBoundObserver(observer: observer)
        return observe(wrapper)
    }

    // MARK: - Remove

    @discardableResult func remove(observer: Observer<DataType>) -> Bool {
        let existingIdx = observers.index { (rhs) -> Bool in
            return observer.hashValue == rhs.observer.hashValue
        }

        if let idx = existingIdx {
            observers.remove(at: idx)
            return true
        } else {
            return false
        }
    }

    // MARK: - Dispatch

    func dispatch(initiator: Observer<DataType>? = nil) {
        // Removes destroyed observers
        observers = observers.filter {
            $0.state != .destroyed
        }

        if let initiator = initiator {
            // Dispaches only to iniciator
            guard let wrapper = observers.first(where: { $0.hashValue == initiator.hashValue }) else {
                return
            }
            considerNotify(wrapper)
        } else {
            // Dispatches to all observers
            observers.forEach {
                self.considerNotify($0)
            }
        }
    }
}

// MARK: - Private

private extension LiveData {
    private func observe(_ wrapper: LifecycleBoundObserver<DataType>) -> Observer<DataType> {
        guard observers.contains(wrapper) == false else {
            fatalError("Unable to register same observer multiple time")
        }
        observers.insert(wrapper)
        return wrapper.observer
    }

    private func considerNotify(_ wrapper: LifecycleBoundObserver<DataType>) {
        // TODO: Check queue

        guard wrapper.state == .active,
            wrapper.lastVersion < version else {
                return
        }
        wrapper.lastVersion = version
        wrapper.observer.update(data)
    }
}
