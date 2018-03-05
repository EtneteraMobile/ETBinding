//
//  Observer.swift
//
//  Created by Jan Čislinský on 15. 12. 2017.
//  Copyright © 2017 Etnetera. All rights reserved.
//

import Foundation

public class Observer<T>: Hashable {
    public let update: (T) -> Void
    public let hashValue: Int

    public init(identity: Int? = nil, update: @escaping (T) -> Void) {
        self.hashValue = identity ?? UUID().uuidString.hashValue
        self.update = update
    }

    public static func ==(lhs: Observer<T>, rhs: Observer<T>) -> Bool {
        return lhs.hashValue == rhs.hashValue
    }
}
