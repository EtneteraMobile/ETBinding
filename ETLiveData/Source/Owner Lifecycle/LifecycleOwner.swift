//
//  LifecycleOwner.swift
//  ETLiveData iOS
//
//  Created by Jan Čislinský on 15. 12. 2017.
//

public protocol LifecycleOwner {
    func on(dealloc: @escaping () -> Void)
}
