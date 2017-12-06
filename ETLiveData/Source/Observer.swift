//
//  Observer.swift
//  Fortuna
//
//  Created by Jan Čislinský on 18. 10. 2017.
//  Copyright © 2017 Etnetera, a.s. All rights reserved.
//

import Foundation

public final class Observer<Value> {
    public typealias IsLoading = Bool
    public typealias Listener = (ObserverValue<Value>) -> Void
    public typealias LoadingListener = (IsLoading, ObserverValue<Value>) -> Void

    // MARK: - Variables
    // MARK: public

    var value: ObserverValue<Value> {
        didSet {
            queue.sync {
                // Triggers listeners
                self.listeners.forEach {
                    $0(value)
                }
                // If loading is in progress, stop it
                if isLoading == true {
                    isLoading = false
                }
            }
        }
    }

    var isLoading: IsLoading {
        didSet {
            queue.sync {
                if oldValue != self.isLoading {
                    self.loadingListeners.forEach {
                        $0(self.isLoading, self.value)
                    }
                }
            }
        }
    }

    // MARK: private

    private let queue = DispatchQueue.global()
    private var listeners: [Listener] = []
    private var loadingListeners: [LoadingListener] = []

    // MARK: - Initialization
    // MARK: public

    public init(_ value: ObserverValue<Value> = .initialized, isLoading: Bool = false) {
        self.value = value
        self.isLoading = isLoading
    }

    // MARK: - Actions
    // MARK: public

    /// Binds given closure as listener to `value` in `Observer`
    /// - Attention: Listener immadiatelly receives current `value`.
    @discardableResult public func bind(_ listener: @escaping Listener) -> Observer {
        queue.sync {
            self.listeners.append(listener)
        }
        listener(value)
        return self
    }

    /// Binds given closure as listener to `loading` in `Observer`
    /// - Attention: Listener immadiatelly receives current `loading`.
    @discardableResult public func onLoading(_ listener: @escaping LoadingListener) -> Observer {
        queue.sync {
            self.loadingListeners.append(listener)
        }
        listener(isLoading, value)
        return self
    }
}
