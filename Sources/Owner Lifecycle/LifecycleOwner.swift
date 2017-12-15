//
//  LifecycleOwner.swift
//  ETLiveData
//
//  Created by Jan Čislinský on 15. 12. 2017.
//  Copyright © 2017 ETLiveData. All rights reserved.
//

public protocol LifecycleOwner {
    func on(dealloc: @escaping () -> Void)
}
