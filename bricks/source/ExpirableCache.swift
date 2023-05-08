//
//  ExpirableCache.swift
//  bricks
//
//  Created by Марина Чемезова on 08.05.2023.
//

import Foundation

public enum ExpirableCacheError: Swift.Error, Equatable {
    case expired
}

public final class ExpirableCache<Storage: bricks.Storage>: FailableQuery {
    public typealias Success = Storage.Stored
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
