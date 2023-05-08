//
//  ExpirableCache.swift
//  bricks
//
//  Created by Марина Чемезова on 08.05.2023.
//

import Foundation

public final class ExpirableCache<Storage: SynchronousStorage>: FailableQuery {
    public enum Error: Swift.Error, Equatable {
        case expired
        case empty
    }
    
    public typealias Success = Storage.Stored
    public typealias Failure = ExpirableCache.Error
    
    private var storage: Storage
    private var validationPolicy: TimestampValidationPolicy
    
    public init(storage: Storage, validationPolicy: TimestampValidationPolicy) {
        self.storage = storage
        self.validationPolicy = validationPolicy
    }
    
    public func load(completion: @escaping (Result<Success, Failure>) -> Void) {
        switch (validationPolicy.validate(storage.timestamp), storage.load()) {
        case (true, .some(let value)): completion(.success(value))
        case (true, .none): completion(.failure(.empty))
        case (false, _): completion(.failure(.expired))
        }
    }
}
