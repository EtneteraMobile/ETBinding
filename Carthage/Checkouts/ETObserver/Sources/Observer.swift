//
//  Observer.swift
//  Etnetera
//
//  Created by Jan Cislinsky on 15. 12. 2017.
//  Copyright © 2017 Etnetera. All rights reserved.
//

import Foundation

public class Observer<T>: Hashable {
    public let update: (T) -> Void
    public let hashValue: Int = UUID().uuidString.hashValue

    public init(update: @escaping (T) -> Void) {
        self.update = update
    }

    public static func ==(lhs: Observer<T>, rhs: Observer<T>) -> Bool {
        return lhs.hashValue == rhs.hashValue
    }
}
