//
//  StateValue.swift
//  ETLiveData iOS
//
//  Created by Jan Čislinský on 15. 12. 2017.
//

public enum StateValue<Value> {
    case success(Value)
    case failure(Swift.Error)
}
