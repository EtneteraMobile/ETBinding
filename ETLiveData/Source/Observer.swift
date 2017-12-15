//
//  Observer.swift
//  ETLiveData iOS
//
//  Created by Jan Čislinský on 15. 12. 2017.
//

import Foundation

public class Observer<T>: Hashable {
    public let update: (T) -> Void
    public let hashValue: Int = Int(arc4random())

    public init(update: @escaping (T) -> Void) {
        self.update = update
    }

    public static func ==(lhs: Observer<T>, rhs: Observer<T>) -> Bool {
        return lhs.hashValue == rhs.hashValue
    }
}
