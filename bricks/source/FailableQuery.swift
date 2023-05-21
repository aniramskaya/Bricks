//
//  FailableQuery.swift
//  bricks
//
//  Created by Марина Чемезова on 21.05.2023.
//

import Foundation

/// ``Query`` whose **Result** associated type is **Swift.Result**` so it may fail and return an error.
public protocol FailableQuery: Query where Result == Swift.Result<Success, Failure> {
    /// Type of data to be loaded
    associatedtype Success
    /// Type of error to be used in a failure case
    associatedtype Failure: Error
}
