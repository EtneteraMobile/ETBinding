//
//  LiveStateData.swift
//  ETLiveData
//
//  Created by Jan Čislinský on 15. 12. 2017.
//  Copyright © 2017 ETLiveData. All rights reserved.
//

/// Wraps generic value from `LiveData` into `StateValue` that adds success and
/// failure states.
public class LiveStateData<Value>: LiveData<StateValue<Value>> {}
