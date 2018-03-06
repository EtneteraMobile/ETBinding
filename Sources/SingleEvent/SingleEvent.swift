//
//  SingleEvent.swift
//
//  Created by Jan Čislinský on 05. 03. 2018.
//  Copyright © 2018 Etnetera. All rights reserved.
//

import Foundation

/// `SingleEvent` is an observable event handler class. Unlike a regular observable,
/// `SingleEvent` is lifecycle-aware, meaning it respects the lifecycle of its owner.
/// This awareness ensures `SingleEvent` only triggers app component observers that
/// are in an active lifecycle state.
///
/// `SingleEvent` is special case of `FutureEvent` because it can be triggered only once per lifetime.
///
///     let onPress = SingleEvent<Void>()
///     let observer = onPress.observeForever {
///         print("Button pressed")
///     }
///     onPress.trigger()
///     // prints Button pressed
///
///     onPress.remove(observer: observer)
///
///     // Second trigger raises fatalError
///     onPress.trigger()
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

    /// Starts observation till any of these conditions aren't met:
    /// 1) `remove(observer:)` is called
    /// 2) the first update occurs
    /// 3) owner is deallocated
    ///
    /// - Attention:
    ///   - After deallocation of owner `onUpdate` will be never called.
    ///
    /// - Warning: Raises fatalError if event was already triggered.
    ///
    /// - Parameters:
    ///   - owner: LifecycleOwner of newly created observation.
    ///   - onUpdate: Closure that is called on change.
    ///
    /// - Returns: Observer that represents update block.
    @discardableResult func observeSingleEvent(owner: LifecycleOwner, onUpdate: @escaping (DataType) -> Void) -> Observer<DataType> {
        return observe(owner, Observer(update: onUpdate))
    }

    /// Starts observation till any of these conditions aren't met:
    /// 1) `remove(observer:)` is called
    /// 2) the first update occurs
    /// 3) owner is deallocated
    ///
    /// - Requires: Given `observer` can be registered only once.
    ///
    /// - Attention:
    ///   - After deallocation of owner `observer.update` will be never called.
    ///
    /// - Warning: Raises fatalError if event was already triggered.
    ///
    /// - Parameters:
    ///   - owner: LifecycleOwner of newly created observation.
    ///   - observer: Observer that is updated on every `data` change.
    func observeSingleEvent(owner: LifecycleOwner, observer: Observer<DataType>) {
        observe(owner, observer)
    }

    /// Starts observation till any of these conditions aren't met:
    /// 1) `remove(observer:)` is called
    /// 2) the first update occurs
    ///
    /// - Warning: Raises fatalError if event was already triggered.
    ///
    /// - Parameters:
    ///   - onUpdate: Closure that is called on `data` change.
    ///
    /// - Returns: Observer that represents update block.
    func observeSingleEventForever(onUpdate: @escaping (DataType) -> Void) -> Observer<DataType> {
        return observe(nil, Observer(update: onUpdate))
    }

    /// Starts observation till any of these conditions aren't met:
    /// 1) `remove(observer:)` is called
    /// 2) the first update occurs
    ///
    /// - Requires: Given `observer` can be registered only once.
    ///
    /// - Warning: Raises fatalError if event was already triggered.
    ///
    /// - Parameters:
    ///   - observer: Observer that is updated on every `data` change.
    func observeSingleEventForever(observer: Observer<DataType>) {
        observe(nil, observer)
    }

    // MARK: - Remove

    /// Unregister given `observer` from observation.
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
    /// Triggers observers.
    ///
    /// - Warning: Must be called only once. Second call raises fatalError.
    public func trigger() {
        triggerObservers(())
    }
}

public extension SingleEvent where DataType: Any {
    /// Triggers observers with given argument.
    ///
    /// - Warning: Must be called only once. Second call raises fatalError.
    ///
    /// - Parameters:
    ///   - arg: Argument that is passed to observers.
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
