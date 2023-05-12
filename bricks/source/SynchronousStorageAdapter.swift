//
//  SynchronousStorageAdapter.swift
//  bricks
//
//  Created by Марина Чемезова on 09.05.2023.
//

import Foundation

/// Adapts ``SynchronousStorage`` to general purpose asynchronous ``Storage``
public class SynchronousStorageAdapter<WrappedStorage: SynchronousStorage>: Storage {
    public typealias Stored = WrappedStorage.Stored
    
    private let wrappee: WrappedStorage
    public init(wrappee: WrappedStorage) {
        self.wrappee = wrappee
    }
    
    public var timestamp: Date? { wrappee.timestamp }
    
    /// Retrieves stored value from wrapped synchronous storage
    ///
    /// Passes ``StorageError/empty`` to completion block when the storage is empty.
    ///
    /// - Parameters:
    ///   - completion: A closure to be called when loading has completed.
    public func load(completion: @escaping (Result<Stored, Error>) -> Void) {
        completion(wrappee.load().map { .success($0) } ?? .failure(StorageError.empty) )
    }
    
    
    /// Saves value to wrapped storage
    ///
    /// Always passes `nil` into completion parameter because memory storage does not emit eny errors.
    public func save(value: WrappedStorage.Stored, completion: @escaping (Error?) -> Void) {
        wrappee.save(value)
        completion(nil)
    }

    /// Cleans wraped storage
    ///
    /// Always passes `nil` into completion parameter because memory storage does not emit eny errors.
    public func clear(completion: @escaping (Error?) -> Void) {
        wrappee.clear()
        completion(nil)
    }
}

public extension Storage {
    func expirableCache(validationPolicy: TimestampValidationPolicy) -> ExpirableCache<Self> {
        return ExpirableCache(storage: self, validationPolicy: validationPolicy)
    }
}
