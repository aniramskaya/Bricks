//
//  InMemoryCacheTests.swift
//  bricksTests
//
//  Created by Марина Чемезова on 07.05.2023.
//

import Foundation
import XCTest
import bricks

///  Synchronous storage
protocol SynchronousStorage {
    associatedtype Stored
    
    /// Retrieves stored value
    func load() -> Stored?
    
    /// Saves value
    func save(_: Stored)
    
    /// Removes stored value, if any
    func clear()
}

// In-memory storage
class InMemoryStorage<Stored>: SynchronousStorage {
    typealias Stored = Stored
    
    var stored: Stored?
    
    func load() -> Stored? { return nil }
    func save(_ value: Stored) {  }
    func clear() {  }

}
class SynchronousStorageTests: XCTestCase {
    func test_load_DeliversNilFromEmptyStorage() {
        let sut = InMemoryStorage<String>()
        
        XCTAssertNil(sut.load())
    }
    
    func test_load_HasNoSideEffectsOnEmptyStorage() {
        let sut = InMemoryStorage<String>()
        
        XCTAssertNil(sut.load())
    }
}
