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
    
    var timestamp: Date? { wrappee.timestamp }
    
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
        let _ = SynchronousStorageAdapter(wrappee: spy)
        
        XCTAssertEqual(spy.messages, [])
    }
    
    func test_timestamp_callsWrappeeTimestamp() throws {
        let spy = SynchronousStorageSpy()
        let sut = SynchronousStorageAdapter(wrappee: spy)

        let _ = sut.timestamp
        
        XCTAssertEqual(spy.messages, [.timestampRead])
    }
}

class SynchronousStorageSpy: SynchronousStorage {
    enum Message: Equatable {
        case timestampRead
        case timestampSave
        case load
        case save(String)
        case clear
    }
    
    var messages: [Message] = []
    
    typealias Stored = String
    
    private var privateTimestamp: Date?
    var timestamp: Date? {
        get {
            messages.append(.timestampRead)
            return privateTimestamp
        }
        set {
            messages.append(.timestampSave)
            privateTimestamp = newValue
        }
    }
    
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
