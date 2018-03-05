//
//  Observable.swift
//
//  Created by Jan Čislinský on 04. 03. 2018.
//  Copyright © 2018 Etnetera. All rights reserved.
//

import Foundation

public protocol Observable: class {
    associatedtype DataType

    /// Starts observation until given owner is alive or `remove(observer:)` is called.
    ///
    /// - Attention:
    ///   - After deallocation of owner `onUpdate` will be never called.
    ///
    /// - Parameters:
    ///   - owner: LifecycleOwner of newly created observation.
    ///   - onUpdate: Closure that is called on change.
    ///
    /// - Returns: Observer that represents update block.
    @discardableResult func observe(owner: LifecycleOwner, onUpdate: @escaping (DataType) -> Void) -> Observer<DataType>

    /// Starts observation until given owner is alive or `remove(observer:)` is called.
    ///
    /// - Requires: Given `observer` can be registered only once.
    ///
    /// - Attention:
    ///   - After deallocation of owner `observer.update` will be never called.
    ///
    /// - Parameters:
    ///   - owner: LifecycleOwner of newly created observation.
    ///   - observer: Observer that is updated on every `data` change.
    func observe(owner: LifecycleOwner, observer: Observer<DataType>)

    /// Starts observation until `remove(observer:)` called.
    ///
    /// - Parameters:
    ///   - onUpdate: Closure that is called on `data` change.
    ///
    /// - Returns: Observer that represents update block.
    func observeForever(onUpdate: @escaping (DataType) -> Void) -> Observer<DataType>

    /// Starts observation until `remove(observer:)` called.
    ///
    /// - Requires: Given `observer` can be registered only once.
    ///
    /// - Parameters:
    ///   - observer: Observer that is updated on every `data` change.
    func observeForever(observer: Observer<DataType>)

    /// Unregister given `observer` from observation.
    ///
    /// - Parameter observer: Observer that has to be removed
    /// - Returns: `True` if observer was unregistered or `false` if observer
    ///            wasn't never registered.
    @discardableResult func remove(observer: Observer<DataType>) -> Bool
}

public extension Observable {
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

// MARK: - Private

internal extension Observable {
    @discardableResult fileprivate func observe(_ wrapper: LifecycleBoundObserver<DataType>) -> Observer<DataType> {
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
            onDealloc(of: owner) { [weak self, unowned wrapper] in
                self?.remove(observer: wrapper.observer)
            }
        }

        return wrapper.observer
    }
}
