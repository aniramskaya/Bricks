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
    func validate(_: Date?) -> Bool
}

class ExpirableCache<Storage: SynchronousStorage>: FailableQuery {
    enum Error: Swift.Error, Equatable {
        case expired
    }
    
    typealias Success = Storage.Stored
    typealias Failure = ExpirableCache.Error
    
    var storage: Storage
    var validationPolicy: TimestampValidationPolicy
    
    init(storage: Storage, validationPolicy: TimestampValidationPolicy) {
        self.storage = storage
        self.validationPolicy = validationPolicy
    }
    
    func load(_ completion: @escaping (Result<Success, Failure>) -> Void) {
        if validationPolicy.validate(storage.timestamp), let stored = storage.load() {
            completion(.success(stored))
        } else {
            completion(.failure(.expired))
        }
    }
}

class ExpirableCacheTests: XCTestCase {
    func test_cache_doesNotMessageUponCreation() throws {
        let spy = StorageSpy()
        let _ = ExpirableCache<StorageSpy>(storage: spy, validationPolicy: spy)
        
        XCTAssertEqual(spy.messages, [])
    }
    
    func test_load_deliversErrorOnExpiredCache() throws {
        let spy = StorageSpy()
        let sut = ExpirableCache<StorageSpy>(storage: spy, validationPolicy: spy)
        spy.isValid = false
        spy.timestamp = Date()

        expect(sut: sut, toCompleteWith: .failure(ExpirableCache.Error.expired))
        
        XCTAssertEqual(spy.messages, [.validate(spy.timestamp)])
    }

    func test_load_deliversSuccessOnNonExpiredCache() throws {
        let spy = StorageSpy()
        let sut = ExpirableCache<StorageSpy>(storage: spy, validationPolicy: spy)
        let value = UUID().uuidString
        spy.value = value
        spy.isValid = true
        spy.timestamp = Date()

        expect(sut: sut, toCompleteWith: .success(value))
        
        XCTAssertEqual(spy.messages, [.validate(spy.timestamp), .load])
    }

    private func expect(sut: ExpirableCache<StorageSpy>, toCompleteWith expectedResult: Result<String, ExpirableCache<StorageSpy>.Error>, file: StaticString = #filePath, line: UInt = #line) {
        
        let exp = expectation(description: "Wait for async query to complete")
        sut.load { result in
            switch (result, expectedResult) {
            case let (.success(received), .success(expected)):
                XCTAssertEqual(received, expected, file: file, line: line)
            case let (.failure(received), .failure(expected)):
                XCTAssertEqual(received, expected, file: file, line: line)
            default:
                XCTFail("Expected \(expectedResult) got \(result) instead", file: file, line: line)
            }
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)
    }

}

private class StorageSpy: SynchronousStorage, TimestampValidationPolicy {
    typealias Stored = String
    
    enum Message: Equatable {
        case load
        case save(String)
        case clear
        case validate(Date?)
    }
    
    var messages: [Message] = []
    
    var timestamp: Date?
    var value: String?
    
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
    func validate(_ timestamp: Date?) -> Bool {
        messages.append(.validate(timestamp))
        return isValid
    }
}
