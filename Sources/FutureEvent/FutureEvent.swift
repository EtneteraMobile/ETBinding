//
//  FutureEvent.swift
//
//  Created by Jan Čislinský on 05. 03. 2018.
//  Copyright © 2018 Etnetera. All rights reserved.
//

import Foundation

/// `FutureEvent` is an observable event handler class. Unlike a regular observable,
/// `FutureEvent` is lifecycle-aware, meaning it respects the lifecycle of its owner.
/// This awareness ensures `FutureEvent` only triggers app component observers that
/// are in an active lifecycle state.
///
///     let onPress = FutureEvent<Void>()
///     let observer = onPress.observeForever {
///         print("Button pressed")
///     }
///     onPress.trigger()
///     // prints Button pressed
///
///     onPress.remove(observer: observer)
///
///     onPress.trigger()
///     // … nothing
public class FutureEvent<Action>: Observable, CustomStringConvertible {
    public typealias DataType = Action

    // MARK: - Variables
    // MARK: public

    public var description: String {
        let observersDesc = observers.reduce("") { accum, current in
            let desc = "\tid: \(current.hashValue), ownerState: \(current.state), owner: \(String(describing: current.owner))\n"
            return accum + desc
        }
        return """
        observers:\n\(observersDesc))
        """
    }

    // MARK: internal

    var observers: Set<LifecycleBoundObserver<DataType>> = []

    // MARK: - Initialization

    public init() {}
}

public extension FutureEvent {
    // MARK: - Observe

    /// Starts observation until given owner is alive or `remove(observer:)` is called.
    ///
    /// - Attention:
    ///   - After deallocation of owner `onUpdate` will be never called.
    ///   - Inside of `onUpdate` closure you are alway on main thread.
    ///
    /// - Parameters:
    ///   - owner: LifecycleOwner of newly created observation.
    ///   - onUpdate: Closure that is called on change.
    ///
    /// - Returns: Observer that represents update block.
    @discardableResult func observe(owner: LifecycleOwner, onUpdate: @escaping (DataType) -> Void) -> Observer<DataType> {
        let wrapper = LifecycleBoundObserver(owner: owner, observer: Observer(update: onUpdate))
        return observe(wrapper)
    }

    /// Starts observation until given owner is alive or `remove(observer:)` is called.
    ///
    /// - Requires: Given `observer` can be registered only once.
    ///
    /// - Attention:
    ///   - After deallocation of owner `observer.update` will be never called.
    ///   - Inside of `observer.update` closure you are alway on main thread.
    ///
    /// - Parameters:
    ///   - owner: LifecycleOwner of newly created observation.
    ///   - observer: Observer that is updated on every `data` change.
    func observe(owner: LifecycleOwner, observer: Observer<DataType>) {
        let wrapper = LifecycleBoundObserver(owner: owner, observer: observer)
        observe(wrapper)
    }

    /// Starts observation until `remove(observer:)` called.
    ///
    /// - Parameters:
    ///   - onUpdate: Closure that is called on `data` change.
    ///   - Inside of `onUpdate` closure you are alway on main thread.
    ///
    /// - Returns: Observer that represents update block.
    @discardableResult func observeForever(onUpdate: @escaping (DataType) -> Void) -> Observer<DataType> {
        let wrapper = LifecycleBoundObserver(observer: Observer(update: onUpdate))
        return observe(wrapper)
    }

    /// Starts observation until `remove(observer:)` called.
    ///
    /// - Requires: Given `observer` can be registered only once.
    ///
    /// - Attention:
    ///   - Inside of `observer.update` closure you are alway on main thread.
    ///
    /// - Parameters:
    ///   - observer: Observer that is updated on every `data` change.
    func observeForever(observer: Observer<DataType>) {
        let wrapper = LifecycleBoundObserver(observer: observer)
        observe(wrapper)
    }

    // MARK: - Remove

    /// Unregister given `observer` from observation.
    ///
    /// - Parameter observer: Observer that has to be removed
    /// - Returns: `True` if observer was unregistered or `false` if observer
    ///            wasn't never registered.
    @discardableResult func remove(observer: Observer<DataType>) -> Bool {
        func onMainQueue() -> Bool {
            let existingIdx = observers.index { (rhs) -> Bool in
                observer.hashValue == rhs.observer.hashValue
            }
            if let idx = existingIdx {
                observers.remove(at: idx)
                return true
            }
            return false
        }
        return Thread.isMainThread ? onMainQueue() : DispatchQueue.main.sync(execute: onMainQueue)
    }
}

// MARK: - Trigger

public extension FutureEvent where DataType == Void {
    /// Triggers observers.
    public func trigger() {
        triggerObservers(())
    }
}

public extension FutureEvent where DataType: Any {
    /// Triggers observers with given argument.
    ///
    /// - Parameters:
    ///   - arg: Argument that is passed to observers.
    public func trigger(_ arg: DataType) {
        triggerObservers(arg)
    }
}

private extension FutureEvent {
    @discardableResult func observe(_ wrapper: LifecycleBoundObserver<DataType>) -> Observer<DataType> {
        func onMainQueue() -> Observer<DataType> {
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
        return Thread.isMainThread ? onMainQueue() : DispatchQueue.main.sync(execute: onMainQueue)
    }
    
    func triggerObservers(_ arg: DataType) {
        func onMainQueue() {
            // Removes destroyed observers
            observers = observers.filter {
                $0.state != .destroyed
            }
            // Triggers all observers
            observers.forEach {
                $0.observer.update(arg)
            }
        }
        return Thread.isMainThread ? onMainQueue() : DispatchQueue.main.sync(execute: onMainQueue)
    }
}
