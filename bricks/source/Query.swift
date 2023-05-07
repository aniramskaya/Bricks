//
//  Loader.swift
//  bricks
//
//  Created by Марина Чемезова on 07.05.2023.
//

import Foundation

/// Basic protocol which declares asynchronous load for any data
public protocol Query {
    associatedtype Result

    func load(_ completion: @escaping (Result) -> Void)
}

/// ``Query`` whose **Result** is ``Swift.Result`` so it may fail and return an error.
public protocol FailableQuery: Query where Result == Swift.Result<Success, Failure> {
    associatedtype Success
    associatedtype Failure: Error
}
