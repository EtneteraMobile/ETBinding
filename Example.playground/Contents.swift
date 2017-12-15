//: Playground - noun: a place where people can play

import Foundation

let d1 = LiveData<String>()
let d2 = LiveStateData<String>()

d1.observeForever { (value) in
    guard let value = value else {
        return
    }

    print(value)
}
d2.observeForever { (value) in
    guard let value = value else {
        return
    }

    if case .success(let data) = value {
        print(data)
    }
}



d1.data = "d1"
d2.data = .success("d2")


























