//
//  LiveOptionalStateData.swift
//  ETBinding
//
//  Created by Jan Čislinský on 07. 02. 2019.
//  Copyright © 2019 Etnetera. All rights reserved.
//

import Foundation

/// Wraps generic value from `LiveData` into `StateValue` that adds success and
/// failure states.
public class LiveOptionalStateData<Value>: LiveData<StateValue<Value>?> {
    public convenience init() {
        self.init(data: nil)
    }
}
