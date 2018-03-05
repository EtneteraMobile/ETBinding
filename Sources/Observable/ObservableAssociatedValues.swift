//
//  ObservableAssociatedValues.swift
//
//  Created by Jan Čislinský on 05. 03. 2018.
//  Copyright © 2018 Etnetera. All rights reserved.
//

import Foundation

// Redundant code because Protocol extension cannot have inheritance clause.

internal extension Observable {
    var observers: Set<LifecycleBoundObserver<DataType>> {
        get {
            return getObservers(from: self, &ObservableAssociatedKeys.observers)
        }
        set {
            setObservers(to: self, newValue, &ObservableAssociatedKeys.observers)
        }
    }

    var lock: NSRecursiveLock {
        return getLock(from: self, &ObservableAssociatedKeys.lock)
    }
}

internal extension SingleEventObservable {
    var observers: Set<LifecycleBoundObserver<DataType>> {
        get {
            return getObservers(from: self, &SingleEventObservableAssociatedKeys.observers)
        }
        set {
            setObservers(to: self, newValue, &SingleEventObservableAssociatedKeys.observers)
        }
    }

    var lock: NSRecursiveLock {
        return getLock(from: self, &SingleEventObservableAssociatedKeys.lock)
    }
}

// MARK: - Helpers

struct ObservableAssociatedKeys {
    static var lock = "obsevableLock"
    static var observers = "observableObservers"
}

struct SingleEventObservableAssociatedKeys {
    static var lock = "singleEventObsevableLock"
    static var observers = "singleEventObservableObservers"
}


fileprivate func getObservers<DataType>(from: Any, _ key: UnsafeRawPointer) -> Set<LifecycleBoundObserver<DataType>> {
    if let rVal = (objc_getAssociatedObject(from, key) as? AssociatedObjectWrapper)?.value as? Set<LifecycleBoundObserver<DataType>> {
        return rVal
    } else {
        let observers: Set<LifecycleBoundObserver<DataType>> = Set()
        objc_setAssociatedObject(from, key, AssociatedObjectWrapper(value: observers), .OBJC_ASSOCIATION_RETAIN)
        return observers
    }
}

fileprivate func setObservers<DataType>(to: Any, _ newValue: Set<LifecycleBoundObserver<DataType>>, _ key: UnsafeRawPointer) {
    objc_setAssociatedObject(to, key, AssociatedObjectWrapper(value: newValue), .OBJC_ASSOCIATION_RETAIN)
}

fileprivate func getLock(from: Any, _ key: UnsafeRawPointer) -> NSRecursiveLock {
    if let rVal = objc_getAssociatedObject(from, key) as? NSRecursiveLock {
        return rVal
    } else {
        let lock = NSRecursiveLock()
        objc_setAssociatedObject(from, key, lock, .OBJC_ASSOCIATION_RETAIN)
        return lock
    }
}
