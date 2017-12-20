//
//  Curry.swift
//  ETLiveData
//
//  Created by Jan Čislinský on 20. 12. 2017.
//  Copyright © 2017 ETLiveData. All rights reserved.
//

import Foundation

func curry<A, B, R>(_ f: @escaping (A, B) -> R) -> (A) -> (B) -> R {
    return { a in { b in f(a, b) } }
}
