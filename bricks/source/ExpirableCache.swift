//
//  ExpirableCache.swift
//  bricks
//
//  Created by Марина Чемезова on 08.05.2023.
//

import Foundation

public enum ExpirableCacheError: Swift.Error, Equatable {
    // Raised when cache is expired
    case expired
}

public final class ExpirableCache<Storage: bricks.Storage>: FailableQuery {
    /// Type of data to be stored in a cache. This type is the same as ``Storage/Stored``
    public typealias Success = Storage.Stored
    /// Error type to be passed into completion closure. It is a **Swift.Error** because we cannot predict possible storage errors.
    public typealias Failure = Swift.Error
    
    private var storage: Storage
    private var validationPolicy: TimestampValidationPolicy
    
    public init(storage: Storage, validationPolicy: TimestampValidationPolicy) {
        self.storage = storage
        self.validationPolicy = validationPolicy
    }
    
    public func load(completion: @escaping (Result<Success, Failure>) -> Void) {
        if validationPolicy.validate(storage.timestamp) {
            storage.load(completion: completion)
        } else {
            completion(.failure(ExpirableCacheError.expired))
        }
    }
}
