//
//  Observer.swift
//
//  Created by Jan Čislinský on 15. 12. 2017.
//  Copyright © 2017 Etnetera. All rights reserved.
//

import Foundation

/// `Observer` wrapps update closure.
///
/// Class adds identity to closure. Implements `Hashable` that uses generated or injected `hashValue` as identifier.
public class Observer<T>: Hashable {
    /// Update closure
    public let update: (T) -> Void
    /// Identity identifier
    public let hashValue: Int


    /// Initializes `Observer` with given identity/hashValue and update closure.
    ///
    /// - Parameters:
    ///   - identity: Identity of observer. If is nil then is generated.
    ///   - update: Update closure.
    public init(identity: Int? = nil, update: @escaping (T) -> Void) {
        self.hashValue = identity ?? UUID().uuidString.hashValue
        self.update = update
    }

    /// `Observer` equal comparator
    public static func ==(lhs: Observer<T>, rhs: Observer<T>) -> Bool {
        return lhs.hashValue == rhs.hashValue
    }
}
