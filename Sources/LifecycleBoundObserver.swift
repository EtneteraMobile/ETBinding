//
//  LifecycleBoundObserver.swift
//  ETLiveData
//
//  Created by Jan Čislinský on 15. 12. 2017.
//  Copyright © 2017 ETLiveData. All rights reserved.
//

import Foundation
import ETObserver

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

    private let isActiveForever: Bool
    private weak var owner: LifecycleOwner?

    init(owner: LifecycleOwner? = nil, observer: Observer<T>) {
        self.owner = owner
        self.observer = observer
        self.isActiveForever = owner == nil
    }
    
    static func ==(lhs: LifecycleBoundObserver<T>, rhs: LifecycleBoundObserver<T>) -> Bool {
        return lhs.hashValue == rhs.hashValue
    }
}
