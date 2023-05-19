//
//  ExpirableCache.swift
//  bricks
//
//  Created by Марина Чемезова on 08.05.2023.
//

import Foundation

public enum ExpirableCacheError: Swift.Error, Equatable {
    /// Raised when cache is expired
    case expired
}

/// ``FailableQuery`` which loads data from ``Storage`` when its timestamp is valid according to ``TimestampValidationPolicy``
public final class ExpiringCache<Storage: bricks.Storage>: FailableQuery {
    /// Type of data to be stored in a cache. This type is the same as ``Storage/Stored``
    public typealias Success = Storage.Stored
    /// Error type to be passed into completion closure. It is a **Swift.Error** because we cannot predict possible storage errors.
    public typealias Failure = Swift.Error
    
    private var storage: Storage
    private var validationPolicy: TimestampValidationPolicy
    
    /// Designated initializer
    ///
    /// - Parameters:
    ///   - storage: Storage to load data from when its timestamp is considered to be valid
    ///   - validationPolicy: A policy to validate storage timestamp
    public init(storage: Storage, validationPolicy: TimestampValidationPolicy) {
        self.storage = storage
        self.validationPolicy = validationPolicy
    }
    
    /// Validates timestamp and loads data from storage
    ///
    /// When called, validates storage timestamp using `validationPolicy` and loads data from storage if the timestamp is valid.
    ///
    /// Passes ``ExpirableCacheError`` to completion when timestamp is invalid.
    ///
    /// Passes storage loading result to completion when timestamp is valid
    public func load(completion: @escaping (Result<Success, Failure>) -> Void) {
        if validationPolicy.validate(storage.timestamp) {
            storage.load(completion: completion)
        } else {
            completion(.failure(ExpirableCacheError.expired))
        }
    }
}

public extension Storage {
    /// Decorates storage whth ``ExpiringCache`` using applied ``TimestampValidationPolicy``
    func expiring(validationPolicy: TimestampValidationPolicy) -> ExpiringCache<Self> {
        return ExpiringCache(storage: self, validationPolicy: validationPolicy)
    }
}
