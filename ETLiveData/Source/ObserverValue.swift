//
//  ObserverValue.swift
//  Fortuna
//
//  Created by Jan Čislinský on 18. 10. 2017.
//  Copyright © 2017 Etnetera, a.s. All rights reserved.
//

import Foundation

public enum ObserverValue<T> {
    case initialized
    case success(T)
    case error(Swift.Error)

    /// Returns true if value is `initialized`.
    public var initialized: Bool {
        if case .initialized = self {
            return true
        }
        return false
    }

    /// Returns the associated value if the result is a success, `nil` otherwise.
    public var success: T? {
        if case .success(let value) = self {
            return value
        }
        return nil
    }

    /// Returns the associated error if the result is a error, `nil` otherwise.
    public var error: Swift.Error? {
        if case .error(let value) = self {
            return value
        }
        return nil
    }
}
