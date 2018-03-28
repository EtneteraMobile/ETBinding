//
//  DeallocTracker.swift
//  ETBinding
//
//  Created by Jan Čislinský on 05. 03. 2018.
//  Copyright © 2018 Etnetera. All rights reserved.
//

import Foundation

final class DeallocTracker {
    let onDealloc: () -> Void

    init(onDealloc: @escaping () -> Void) {
        self.onDealloc = onDealloc
    }

    deinit {
        onDealloc()
    }
}

/// Executes action upon deallocation of owner
///
/// - Parameters:
///   - owner: Owner to track.
///   - closure: Closure to execute.
public func onDealloc(of owner: Any, closure: @escaping () -> Void) {
    while true {
        // Generates random key for association and checks that it wasn't used already
        if let key = UnsafeRawPointer(bitPattern: UInt(arc4random())), objc_getAssociatedObject(owner, key) == nil {
            let tracker = DeallocTracker(onDealloc: closure)
            objc_setAssociatedObject(owner, key, tracker, .OBJC_ASSOCIATION_RETAIN)
            break
        }
    }
}
