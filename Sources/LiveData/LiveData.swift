//
//  LiveData.swift
//  ETBinding
//
//  Created by Jan Čislinský on 15. 12. 2017.
//  Copyright © 2017 ETBinding. All rights reserved.
//

import Foundation

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
public class LiveData<Value>: Observable {
    public typealias DataType = Value?

    // MARK: - Variables
    // MARK: public

    /// The current value that is dispatched after assignment.
    /// Every data change is delivered to observers only once despite of
    /// multiple calls of `dispatch`.
    public var data: DataType {
        didSet {
            version += 1
            dispatch()
        }
    }

    // MARK: internal

    var observers: Set<LifecycleBoundObserver<DataType>> = []
    var lock: NSRecursiveLock = NSRecursiveLock()

    // MARK: private

    private var version: Int = Constants.startVersion

    // MARK: - Initialization

    /// Initializes `LiveData` with given data.
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
    
    // MARK: - Dispatch

    /// Dispatches current value to observers.
    ///
    /// - Requires: Initiator has to be registered for observation!
    ///
    /// - Parameter initiator: Initiator of dispatch, dispatches value only him
    ///                        if is given.
    ///
    /// - Attention: Data are dispatched to observers based on last delivered
    /// version. Every version is delivered only once despite of multiple
    /// calls of `dispatch`.
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

    func considerNotify(_ wrapper: LifecycleBoundObserver<DataType>) {
        guard wrapper.state == .active,
            wrapper.lastVersion < version else {
                return
        }
        wrapper.lastVersion = version
        wrapper.observer.update(data)
    }
}
