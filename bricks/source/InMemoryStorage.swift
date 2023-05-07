//
//  InMemoryStorage.swift
//  bricks
//
//  Created by Марина Чемезова on 07.05.2023.
//

import Foundation

///  Synchronous storage
public protocol SynchronousStorage {
    associatedtype Stored
    
    /// Retrieves stored value
    func load() -> Stored?
    
    /// Saves value
    func save(_: Stored)
    
    /// Removes stored value, if any
    func clear()
}

// In-memory storage
public class InMemoryStorage<Stored>: SynchronousStorage {
    private var stored: Stored?
    
    public init() {}
    
    public func load() -> Stored? { return stored }
    public func save(_ value: Stored) { stored = value }
    public func clear() { stored = nil }
}
