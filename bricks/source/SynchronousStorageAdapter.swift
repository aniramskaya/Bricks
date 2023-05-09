//
//  SynchronousStorageAdapter.swift
//  bricks
//
//  Created by Марина Чемезова on 09.05.2023.
//

import Foundation

public class SynchronousStorageAdapter<WrappedStorage: SynchronousStorage>: Storage {
    public typealias Stored = WrappedStorage.Stored
    
    private let wrappee: WrappedStorage
    public init(wrappee: WrappedStorage) {
        self.wrappee = wrappee
    }
    
    public var timestamp: Date? { wrappee.timestamp }
    
    public func load(completion: @escaping (Result<Stored, Error>) -> Void) {
        completion(wrappee.load().map { .success($0) } ?? .failure(StorageError.empty) )
    }
    
    public func save(value: WrappedStorage.Stored, completion: @escaping (Error?) -> Void) {
        wrappee.save(value)
        completion(nil)
    }

    public func clear(completion: @escaping (Error?) -> Void) {
        wrappee.clear()
        completion(nil)
    }
}
