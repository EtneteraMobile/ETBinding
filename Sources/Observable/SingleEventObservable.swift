//
//  SingleEventObservable.swift
//
//  Created by Jan Čislinský on 04. 03. 2018.
//  Copyright © 2018 Etnetera. All rights reserved.
//

import Foundation

public protocol SingleEventObservable: class {
    associatedtype DataType

    /// Starts observation until given owner is alive or
    /// - `remove(observer:)` is called,
    /// - or `onUpdate` is triggered.
    ///
    /// - Attention:
    ///   - After deallocation of owner `onUpdate` will be never called.
    ///   - `onUpdate` is called only once.
    ///
    /// - Parameters:
    ///   - owner: LifecycleOwner of newly created observation.
    ///   - onUpdate: Closure that is called on change.
    ///
    /// - Returns: Observer that represents update block.
    @discardableResult func observeSingleEvent(owner: LifecycleOwner, onUpdate: @escaping (DataType) -> Void) -> Observer<DataType>

    /// Starts observation until given owner is alive or
    /// - `remove(observer:)` is called,
    /// - or `onUpdate` is triggered.
    ///
    /// - Requires: Given `observer` can be registered only once.
    ///
    /// - Attention:
    ///   - After deallocation of owner `observer.update` will be never called.
    ///   - `onUpdate` is called only once.
    ///
    /// - Parameters:
    ///   - owner: LifecycleOwner of newly created observation.
    ///   - observer: Observer that is updated on every `data` change.
    func observeSingleEvent(owner: LifecycleOwner, observer: Observer<DataType>)

    /// Starts observation until
    /// - `remove(observer:)` is called,
    /// - or `onUpdate` is triggered.
    ///
    /// - Attention:
    ///   - `onUpdate` is called only once.
    ///
    /// - Parameters:
    ///   - onUpdate: Closure that is called on `data` change.
    ///
    /// - Returns: Observer that represents update block.
    func observeSingleEventForever(onUpdate: @escaping (DataType) -> Void) -> Observer<DataType>

    /// Starts observation until
    /// - `remove(observer:)` is called,
    /// - or `onUpdate` is triggered.
    ///
    /// - Requires: Given `observer` can be registered only once.
    ///
    /// - Attention:
    ///   - `onUpdate` is called only once.
    ///
    /// - Parameters:
    ///   - observer: Observer that is updated on every `data` change.
    func observeSingleEventForever(observer: Observer<DataType>)

    /// Unregister given `observer` from observation.
    ///
    /// - Parameter observer: Observer that has to be removed
    /// - Returns: `True` if observer was unregistered or `false` if observer
    ///            wasn't never registered.
    @discardableResult func remove(observer: Observer<DataType>) -> Bool
}

public extension SingleEventObservable {
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

// MARK: - Private

internal extension SingleEventObservable {
    @discardableResult fileprivate func observe(_ owner: LifecycleOwner?, _ observer: Observer<DataType>) -> Observer<DataType> {
        lock.lock()
        defer {
            lock.unlock()
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
}
