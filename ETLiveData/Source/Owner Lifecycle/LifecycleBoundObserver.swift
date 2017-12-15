//
//  LifecycleBoundObserver.swift
//  ETLiveData iOS
//
//  Created by Jan Čislinský on 15. 12. 2017.
//

import Foundation

public class LifecycleBoundObserver<T>: Hashable {
    public var hashValue: Int {
        return observer.hashValue
    }
    public private(set) var state: LifecycleState = .active
    public let observer: Observer<T>
    internal var lastVersion: Int = Constants.startVersion
    private let owner: LifecycleOwner?

    init(owner: LifecycleOwner? = nil, observer: Observer<T>) {
        self.owner = owner
        self.observer = observer

        if let owner = owner {
            owner.on(dealloc: { [unowned self] in
                self.state = .destroyed
            })
        }
    }

    deinit {
        // TODO: Removes DeallocTracker
    }

    public static func ==(lhs: LifecycleBoundObserver<T>, rhs: LifecycleBoundObserver<T>) -> Bool {
        return lhs.hashValue == rhs.hashValue
    }
}
