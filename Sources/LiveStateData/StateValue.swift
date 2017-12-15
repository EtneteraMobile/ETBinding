//
//  StateValue.swift
//  ETLiveData
//
//  Created by Jan Čislinský on 15. 12. 2017.
//  Copyright © 2017 ETLiveData. All rights reserved.
//

public enum StateValue<Value> {
    case success(Value)
    case failure(Swift.Error)
}
