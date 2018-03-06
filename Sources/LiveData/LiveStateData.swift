//
//  LiveStateData.swift
//  ETBinding
//
//  Created by Jan Čislinský on 15. 12. 2017.
//  Copyright © 2017 ETBinding. All rights reserved.
//

/// Wraps generic value from `LiveData` into `StateValue` that adds success and
/// failure states.
public class LiveStateData<Value>: LiveData<StateValue<Value>> {}
