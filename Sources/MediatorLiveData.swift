//
//  MediatorLiveData.swift
//  ETLiveData
//
//  Created by Jan Čislinský on 14. 02. 2018.
//  Copyright © 2018 ETLiveData. All rights reserved.
//

import Foundation
import ETObserver

public final class MediatorLiveData<Value>: LiveData<Value> {
    private var sources :[LiveData<Value>] = []
    private lazy var observer: Observer<DataType> = Observer { data in
        self.data = data
    }

    deinit {
        sources.forEach {
            $0.remove(observer: self.observer)
        }
    }

    public func add(source: LiveData<Value>) {
        sources.append(source)
        source.observeForever(observer: observer)
    }
}
