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

public class LifecycleBoundObserver<T>: Hashable {
    public var hashValue: Int {
        return observer.hashValue
    }
    public var state: LifecycleState {
        get {
            return owner != nil || isActiveForever ? .active : .destroyed
        }
    }
    public let observer: Observer<T>
    internal var lastVersion: Int = Constants.startVersion
    private let isActiveForever: Bool
    private weak var owner: LifecycleOwner?

    init(owner: LifecycleOwner? = nil, observer: Observer<T>) {
        self.owner = owner
        self.observer = observer
        self.isActiveForever = owner == nil
    }
    
    public static func ==(lhs: LifecycleBoundObserver<T>, rhs: LifecycleBoundObserver<T>) -> Bool {
        return lhs.hashValue == rhs.hashValue
    }
}
