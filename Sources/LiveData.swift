//
//  LiveData.swift
//  ETLiveData
//
//  Created by Jan Čislinský on 15. 12. 2017.
//  Copyright © 2017 ETLiveData. All rights reserved.
//

import Foundation
import ETObserver

/// `LiveData` is an observable data holder class. Unlike a regular observable,
/// `LiveData` is lifecycle-aware, meaning it respects the lifecycle of its owner.
/// This awareness ensures `LiveData` only updates app component observers that
/// are in an active lifecycle state.
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

    /// The current value that is dispatched after assignment.
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

    /// Starts observing changes of `data` until `remove(observer:)` is called.
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

    /// Starts observing changes of `data` until `remove(observer:)` is called.
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

    /// Starts observing changes of `data` until any of these conditions aren't met:
    /// 1) `remove(observer:)` is called
    /// 2) the first update occurs
    /// 3) owner is deallocated
    ///
    /// - Attention:
    ///   - Observer is automatically removed after the first dispatch.
    ///
    /// - Parameters:
    ///   - onUpdate: Closure that is called on `data` change.
    ///
    /// - Returns: Observer that represents update block.
    @discardableResult func observeSingleEvent(owner: LifecycleOwner, onUpdate: @escaping (DataType) -> Void) -> Observer<DataType> {
        let observer = Observer(update: onUpdate)
        observeSingleEvent(owner: owner, observer: observer)
        return observer
    }

    /// Starts observing changes of `data` until any of these conditions aren't met:
    /// 1) `remove(observer:)` is called
    /// 2) the first update occurs
    /// 3) owner is deallocated
    ///
    /// - Requires: Given `observer` can be registered only once per `LiveData`
    ///
    /// - Attention:
    ///   - Observer is automatically removed after the first dispatch.
    ///
    /// - Parameters:
    ///   - observer: Observer that is updated on every `data` change.
    func observeSingleEvent(owner: LifecycleOwner, observer: Observer<DataType>) {
        weak var weakOnceObserver: Observer<DataType>?
        let onceObserver: Observer<DataType> = ETObserver.Observer { [unowned self] data in
            if let onceObserver = weakOnceObserver {
                self.remove(observer: onceObserver)
            }
            observer.update(data)
        }
        weakOnceObserver = onceObserver
        observe(owner: owner, observer: onceObserver)
    }

    /// Starts observing changes of `data` until any of these conditions aren't met:
    /// 1) `remove(observer:)` is called
    /// 2) the first update occurs
    ///
    /// - Attention:
    ///   - Observer is automatically removed after the first dispatch.
    ///
    /// - Parameters:
    ///   - onUpdate: Closure that is called on `data` change.
    ///
    /// - Returns: Observer that represents update block.
    @discardableResult func observeSingleEventForever(onUpdate: @escaping (DataType) -> Void) -> Observer<DataType> {
        let observer = Observer(update: onUpdate)
        observeSingleEventForever(observer: observer)
        return observer
    }

    /// Starts observing changes of `data` until any of these conditions aren't met:
    /// 1) `remove(observer:)` is called
    /// 2) the first update occurs
    ///
    /// - Attention:
    ///   - Observer is automatically removed after the first dispatch.
    ///
    /// - Parameters:
    ///   - observer: Observer that is updated on every `data` change.
    func observeSingleEventForever(observer: Observer<DataType>) {
        weak var weakOnceObserver: Observer<DataType>?
        let onceObserver: Observer<DataType> = ETObserver.Observer { [unowned self] data in
            if let onceObserver = weakOnceObserver {
                self.remove(observer: onceObserver)
            }
            observer.update(data)
        }
        weakOnceObserver = onceObserver
        observeForever(observer: onceObserver)
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
