//
//  SynchronousStorageAdapter.swift
//  bricksTests
//
//  Created by Марина Чемезова on 09.05.2023.
//

import Foundation
import XCTest
import bricks

class SynchronousStorageAdapter<WrappedStorage: SynchronousStorage>: Storage {
    typealias Stored = WrappedStorage.Stored
    
    let wrappee: WrappedStorage
    init(wrappee: WrappedStorage) {
        self.wrappee = wrappee
    }
    
    var timestamp: Date?
    
    func load(completion: (Result<Stored, Error>) -> Void) {
        
    }
    
    func save(value: WrappedStorage.Stored, completion: (Error?) -> Void) {
        
    }

    func clear(completion: (Error?) -> Void) {
        
    }
}

class SynchronousStorageAdapterTests: XCTestCase {
    func test_adapter_doesNotMessageUponCreation() throws {
        let spy = SynchronousStorageSpy()
        let sut = SynchronousStorageAdapter(wrappee: spy)
        
        XCTAssertEqual(spy.messages, [])
    }
}

class SynchronousStorageSpy: SynchronousStorage {
    enum Message: Equatable {
        case load
        case save(String)
        case clear
    }
    
    var messages: [Message] = []
    
    typealias Stored = String
    
    var timestamp: Date?
    
    var value: Stored?

    func load() -> String? {
        messages.append(.load)
        return value
    }
    
    func save(_ value: String) {
        messages.append(.save(value))
    }

    func clear() {
        messages.append(.clear)
    }
}
