//
//  LifecycleBoundObserver.swift
//  ETLiveData
//
//  Created by Jan Čislinský on 15. 12. 2017.
//  Copyright © 2017 ETLiveData. All rights reserved.
//

import Foundation
import ETObserver

public class LifecycleBoundObserver<T>: Hashable {
    public var hashValue: Int {
        return observer.hashValue
    }
    public private(set) var state: LifecycleState = .active
    public let observer: Observer<T>
    internal var lastVersion: Int = Constants.startVersion
    private weak var owner: LifecycleOwner?

    init(owner: LifecycleOwner? = nil, observer: Observer<T>) {
        self.observer = observer
        self.owner = owner

        owner?.on(dealloc: { [weak self] in
            self?.state = .destroyed
        })
    }
    
    public static func ==(lhs: LifecycleBoundObserver<T>, rhs: LifecycleBoundObserver<T>) -> Bool {
        return lhs.hashValue == rhs.hashValue
    }
}
