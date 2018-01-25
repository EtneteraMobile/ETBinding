//
//  LiveData.swift
//  ETLiveData
//
//  Created by Jan Čislinský on 15. 12. 2017.
//  Copyright © 2017 ETLiveData. All rights reserved.
//

import Foundation
import ETObserver

/// `LiveData` dispatches new `data` to all registered observers automatically.
///
///     let liveData = LiveData(data: "Initial")
///     let observer = liveData.observeForever { (data) in
///         print("\(String(describing: data))")
///     }
///     liveData.dispatch()
///     // prints Initial
///     liveData.data = "1"
///     // prints 1
///     liveData.remove(observer: observer)
///     liveData.data = "2"
///     // … nothing
public class LiveData<Value> {

    // MARK: - Variables
    // MARK: public

    public typealias DataType = Value?
    public var data: DataType {
        didSet {
            version += 1
            dispatch()
        }
    }

    // MARK: internal

    /// Registered observers of data
    var observers: Set<LifecycleBoundObserver<DataType>> = []

    // MARK: private

    private var version: Int = Constants.startVersion
    private let lock = NSRecursiveLock()

    // MARK: - Initialization

    /// Initializes `LiveData` with given data.
    public init(data: DataType = nil) {
        self.data = data
    }
}

// MARK: - Public

public extension LiveData {

    // MARK: - Observe

    /// Starts observing changes of `data` until given owner is alive or
    /// `remove(observer:)` called.
    ///
    /// - Attention:
    ///   - Every data change is delivered only once despite of multiple
    ///     calls of `dispatch`.
    ///   - After deallocation of owner `onUpdate` will be never called.
    ///
    /// - Parameters:
    ///   - owner: LifecycleOwner of newly created observation.
    ///   - onUpdate: Closure that is called on `data` change.
    ///
    /// - Returns: Observer that represents update block.
    @discardableResult func observe(owner: LifecycleOwner, onUpdate: @escaping (DataType) -> Void) -> Observer<DataType> {
        let wrapper = LifecycleBoundObserver(owner: owner, observer: Observer(update: onUpdate))
        return observe(wrapper)
    }

    /// Starts observing changes of `data` until given owner is alive or
    /// `remove(observer:)` called.
    ///
    /// - Requires: Given `observer` can be registered only once per `LiveData`
    ///
    /// - Attention:
    ///   - Every data change is delivered only once despite of multiple
    ///     calls of `dispatch`.
    ///   - After deallocation of owner `observer.update` will be never called.
    ///
    /// - Parameters:
    ///   - owner: LifecycleOwner of newly created observation.
    ///   - observer: Observer that is updated on every `data` change.
    func observe(owner: LifecycleOwner, observer: Observer<DataType>) {
        let wrapper = LifecycleBoundObserver(owner: owner, observer: observer)
        observe(wrapper)
    }

    /// Starts observing changes of `data` until `remove(observer:)` called.
    ///
    /// - Attention:
    ///   - Every data change is delivered only once despite of multiple
    ///     calls of `dispatch`.
    ///
    /// - Parameters:
    ///   - onUpdate: Closure that is called on `data` change.
    ///
    /// - Returns: Observer that represents update block.
    func observeForever(onUpdate: @escaping (DataType) -> Void) -> Observer<DataType> {
        let wrapper = LifecycleBoundObserver(observer: Observer(update: onUpdate))
        return observe(wrapper)
    }

    /// Starts observing changes of `data` until `remove(observer:)` called.
    ///
    /// - Requires: Given `observer` can be registered only once per `LiveData`
    ///
    /// - Attention:
    ///   - Every data change is delivered only once despite of multiple
    ///     calls of `dispatch`.
    ///
    /// - Parameters:
    ///   - observer: Observer that is updated on every `data` change.
    @discardableResult func observeForever(observer: Observer<DataType>) -> Observer<DataType> {
        let wrapper = LifecycleBoundObserver(observer: observer)
        return observe(wrapper)
    }

    // MARK: - Remove


    /// Unregister given `observer` from `data` observation.
    ///
    /// - Parameter observer: Observer that has to be removed
    /// - Returns: `True` if observer was unregistered or `false` if observer
    ///            wasn't never registered.
    @discardableResult func remove(observer: Observer<DataType>) -> Bool {
        lock.lock()
        defer {
            lock.unlock()
        }
        let existingIdx = observers.index { (rhs) -> Bool in
            return observer.hashValue == rhs.observer.hashValue
        }
        if let idx = existingIdx {
            observers.remove(at: idx)
            return true
        }
        return false
    }

    // MARK: - Dispatch

    /// Dispatches current value to observers that don't have it still.
    ///
    /// - Requires: Initiator has to be registered for observation!
    ///
    /// - Parameter initiator: Initiator of dispatch, dispatches value only him
    ///                        if is given.
    func dispatch(initiator: Observer<DataType>? = nil) {
        lock.lock()
        defer {
            lock.unlock()
        }
        // Removes destroyed observers
        observers = observers.filter {
            $0.state != .destroyed
        }

        if let initiator = initiator {
            // Dispaches only to iniciator
            guard let wrapper = observers.first(where: { $0.hashValue == initiator.hashValue }) else {
                fatalError("Initiator was never registered for observation")
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
    @discardableResult private func observe(_ wrapper: LifecycleBoundObserver<DataType>) -> Observer<DataType> {
        lock.lock()
        defer {
            lock.unlock()
        }
        guard observers.contains(wrapper) == false else {
            fatalError("Unable to register same observer multiple time")
        }
        observers.insert(wrapper)
        return wrapper.observer
    }

    private func considerNotify(_ wrapper: LifecycleBoundObserver<DataType>) {
        guard wrapper.state == .active,
            wrapper.lastVersion < version else {
                return
        }
        wrapper.lastVersion = version
        wrapper.observer.update(data)
    }
}

func hovno() {
    let vc = NSObject()
    let liveData = LiveData(data: "Initial")
    let observer = liveData.observe(owner: vc) { (data) in
        print("\(String(describing: data))")
    }
    liveData.dispatch()
    // prints Initial
    liveData.data = "1"
    // prints 1
    liveData.remove(observer: observer)
    liveData.data = "2"
    // … nothing
}
