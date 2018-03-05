//
//  StateValue.swift
//  ETBinding
//
//  Created by Jan Čislinský on 15. 12. 2017.
//  Copyright © 2017 ETBinding. All rights reserved.
//

/// Value with state added
public enum StateValue<Value> {
    /// Success value
    case success(Value)
    /// Error for failured value
    case failure(Swift.Error)
}
