//
//  LiveOptionalData.swift
//  ETBinding
//
//  Created by Jan Čislinský on 07. 02. 2019.
//  Copyright © 2019 Etnetera. All rights reserved.
//

import Foundation

/// `LiveData` is an observable data holder class. Unlike a regular observable,
/// `LiveData` is lifecycle-aware, meaning it respects the lifecycle of its owner.
/// This awareness ensures `LiveData` only updates app component observers that
/// are in an active lifecycle state.
///
///     let liveData = LiveData(data: "Initial")
///     let observer = liveData.observeForever { (data) in
///         print("\(String(describing: data))")
///     }
///     liveData.dispatch()
///     // prints Initial
///     liveData.data = "1"
///     // prints 1
///     liveData.remove(observer: observer)
///     liveData.data = "2"
///     // … nothing
public class LiveOptionalData<Value>: LiveData<Value?> {
    public convenience init() {
        self.init(data: nil)
    }
}
