//
//  ExpirableCache.swift
//  bricksTests
//
//  Created by Марина Чемезова on 08.05.2023.
//

import Foundation
import XCTest
import bricks

protocol TimestampValidationPolicy {
    func validate(_: Date) -> Bool
}

class ExpirableCache<Storage: SynchronousStorage, Failure: Error>: FailableQuery {
    typealias Success = Storage.Stored
    
    var storage: Storage
    var validationPolicy: TimestampValidationPolicy
    
    init(storage: Storage, validationPolicy: TimestampValidationPolicy) {
        self.storage = storage
        self.validationPolicy = validationPolicy
    }
    
    func load(_ completion: @escaping (Result<Success, Failure>) -> Void) {
        
    }
}

class ExpirableCacheTests: XCTestCase {
    func test_cache_doesNotMessageUponCreation() {
        let spy = StorageSpy()
        let _ = ExpirableCache<StorageSpy, Swift.Error>(storage: spy, validationPolicy: spy)
        
        XCTAssertEqual(spy.messages, [])
    }
}

private class StorageSpy: SynchronousStorage, TimestampValidationPolicy {
    typealias Stored = String
    
    enum Message: Equatable {
        case load
        case save(String)
        case clear
        case validate(Date)
    }
    
    var messages: [Message] = []
    
    var timestamp: Date?
    private var value: String?
    
    func load() -> String? {
        messages.append(.load)
        return value
    }
    
    func save(_ value: String) {
        messages.append(.save(value))
        self.value = value
    }
    
    func clear() {
        messages.append(.clear)
        value = nil
    }
    
    var isValid = true
    func validate(_: Date) -> Bool {
        return isValid
    }
}
