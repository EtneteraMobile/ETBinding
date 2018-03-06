//
//  SingleEventObservable.swift
//
//  Created by Jan Čislinský on 04. 03. 2018.
//  Copyright © 2018 Etnetera. All rights reserved.
//

import Foundation

/// Declares methods for observation.
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
    /// - Warning: Raises fatalError if event was already triggered.
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
    /// - Warning: Raises fatalError if event was already triggered.
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
    /// - Warning: Raises fatalError if event was already triggered.
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
    /// - Warning: Raises fatalError if event was already triggered.
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
