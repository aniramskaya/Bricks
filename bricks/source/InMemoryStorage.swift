//
//  InMemoryStorage.swift
//  bricks
//
//  Created by Марина Чемезова on 07.05.2023.
//

import Foundation

///  Synchronous storage. Stores a value synchronously on the thread it was called from.
public protocol SynchronousStorage {
    associatedtype Stored
    
    var timestamp: Date? { get }
    
    /// Retrieves stored value
    func load() -> Stored?
    
    /// Saves value
    func save(_: Stored)
    
    /// Removes stored value, if any
    func clear()
}

/// In-memory storage simply holds the data passed into `load` method
public final class InMemoryStorage<Stored>: SynchronousStorage {
    private var stored: Stored?
    public private(set) var timestamp: Date?
    
    public init() {}
    
    /// Retrieves stored value overriding the previous one
    public func load() -> Stored? { return stored }
    public func save(_ value: Stored) {
        stored = value
        timestamp = Date()
    }
    public func clear() { stored = nil }
}
