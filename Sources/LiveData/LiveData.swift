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

    // MARK: - Variables
    // MARK: public

    public typealias DataType = Value?

    /// The current value that is dispatched after assignment.
    /// Every data change is delivered to observers only once despite of
    /// multiple calls of `dispatch`.
    public var data: DataType {
        didSet {
            version += 1
            dispatch()
        }
    }

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
    func considerNotify(_ wrapper: LifecycleBoundObserver<DataType>) {
        guard wrapper.state == .active,
            wrapper.lastVersion < version else {
                return
        }
        wrapper.lastVersion = version
        wrapper.observer.update(data)
    }
}
