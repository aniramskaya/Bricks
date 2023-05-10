//
//  InMemoryStorage.swift
//  bricks
//
//  Created by Марина Чемезова on 07.05.2023.
//

import Foundation

/// In-memory storage simply holds the data passed into `load` method
public final class InMemoryStorage<Stored>: SynchronousStorage {
    private var stored: Stored?
    public private(set) var timestamp: Date?
    
    public init() {}
    
    public func load() -> Stored? { return stored }

    /// Stores value overriding the previous one
    public func save(_ value: Stored) {
        stored = value
        timestamp = Date()
    }
    
    public func clear() {
        stored = nil
        timestamp = nil
    }
}

public extension InMemoryStorage {
    func adapted() -> SynchronousStorageAdapter<InMemoryStorage> {
        SynchronousStorageAdapter(wrappee: self)
    }
}
