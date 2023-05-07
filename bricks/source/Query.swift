//
//  Loader.swift
//  bricks
//
//  Created by Марина Чемезова on 07.05.2023.
//

import Foundation

/// An abstraction which declares asynchronous load for any data
public protocol Query {
    associatedtype Result

    /// Loads **Result** in an asynchronous manner with completion
    func load(_ completion: @escaping (Result) -> Void)
}

/// ``Query`` whose **Result** is ``Swift.Result`` so it may fail and return an error.
public protocol FailableQuery: Query where Result == Swift.Result<Success, Failure> {
    associatedtype Success
    associatedtype Failure: Error
}
