//
//  StoringQuery.swift
//  bricks
//
//  Created by Марина Чемезова on 07.05.2023.
//

import Foundation

/// ``FailableQuery`` which stores loaded data into a storage on success
public final class StoringQuery<WrappedQuery: FailableQuery, WrappedStorage: Storage>: FailableQuery where WrappedStorage.Stored == WrappedQuery.Success
{
    public typealias Success = WrappedQuery.Success
    public typealias Failure = WrappedQuery.Failure
    public typealias Result = WrappedQuery.Result
    
    private var query: WrappedQuery
    private var storage: WrappedStorage
    
    /// Designated initializer.
    ///
    /// - Parameters:
    ///   - query: FailableQuery to wrap
    ///   - storage: Storage to save succesfully loaded data
    public init(query: WrappedQuery, storage: WrappedStorage) {
        self.query = query
        self.storage = storage
    }
    
    /// Loads data from `query` passed in initializer and if it succeeded saves it into `storage`
    ///
    /// > Impotant: Method does not care about waiting for saving result and checking it. All saving errors are discarded.
    /// - Parameters:
    ///   - completion: A closure which is called when the loading process has complete.
    public func load(completion: @escaping (WrappedQuery.Result) -> Void) {
        query.load { [weak self] result in
            guard let self else { return }
            self.saveIfSuccess(result)
            completion(result)
        }
    }
    
    private func saveIfSuccess(_ result: WrappedQuery.Result) {
        if let value = try? result.get() {
            storage.save(value: value) { _ in }
        }
    }
}

public extension FailableQuery {
    func storing<WrappedStorage: Storage>(into storage: WrappedStorage) -> StoringQuery<Self, WrappedStorage> where WrappedStorage.Stored == Success {
        StoringQuery(query: self, storage: storage)
    }
}
