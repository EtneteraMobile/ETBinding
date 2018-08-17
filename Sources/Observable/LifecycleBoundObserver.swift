//
//  LifecycleBoundObserver.swift
//
//  Created by Jan Čislinský on 15. 12. 2017.
//  Copyright © 2017 Etnetera. All rights reserved.
//

import Foundation

/// Lifecycle object for which is observer bound to
public typealias LifecycleOwner = AnyObject

/// Wrapper for `Observer` and `LifecycleOwner` whose state determines that
/// `Observer` has to be active or not according lifecycle of owner.
class LifecycleBoundObserver<T>: Hashable {
    var hashValue: Int {
        return observer.hashValue
    }
    /// Lifecycle state of owner if was set in init otherwise returns forever `.active`
    var state: LifecycleState {
        get {
            return owner != nil || isActiveForever ? .active : .destroyed
        }
    }
    /// Observers that delivers updates
    let observer: Observer<T>
    /// Last version of delivered data to observer
    var lastVersion: Int = Constants.startVersion

    weak var owner: LifecycleOwner?
    private let isActiveForever: Bool

    init(owner: LifecycleOwner? = nil, observer: Observer<T>) {
        self.owner = owner
        self.observer = observer
        self.isActiveForever = owner == nil
    }
    
    static func ==(lhs: LifecycleBoundObserver<T>, rhs: LifecycleBoundObserver<T>) -> Bool {
        return lhs.hashValue == rhs.hashValue
    }
}
