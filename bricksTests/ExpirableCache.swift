//
//  ExpirableCache.swift
//  bricksTests
//
//  Created by Марина Чемезова on 08.05.2023.
//

import Foundation
import XCTest
import bricks

class ExpirableCacheTests: XCTestCase {
    func test_cache_doesNotMessageUponCreation() throws {
        let (_, spy) = makeSUT()
        
        XCTAssertEqual(spy.messages, [])
    }
    
    func test_load_deliversErrorOnExpiredCache() throws {
        let (sut, spy) = makeSUT()
        spy.isValid = false
        spy.timestamp = Date()

        expect(sut: sut, toCompleteWith: .failure(ExpirableCacheError.expired))
        
        XCTAssertEqual(spy.messages, [.validate(spy.timestamp)])
    }

    func test_load_deliversErrorOnEmptyCache() throws {
        let (sut, spy) = makeSUT()
        spy.isValid = true
        spy.timestamp = Date()

        expect(sut: sut, toCompleteWith: .failure(StorageSpyError.empty))
        
        XCTAssertEqual(spy.messages, [.validate(spy.timestamp), .load])
    }

    func test_load_deliversSuccessOnNonExpiredCache() throws {
        let (sut, spy) = makeSUT()
        let value = UUID().uuidString
        spy.value = value
        spy.isValid = true
        spy.timestamp = Date()

        expect(sut: sut, toCompleteWith: .success(value))
        
        XCTAssertEqual(spy.messages, [.validate(spy.timestamp), .load])
    }
    
    private func makeSUT() -> (ExpirableCache<StorageSpy>, StorageSpy) {
        let spy = StorageSpy()
        let sut = ExpirableCache<StorageSpy>(storage: spy, validationPolicy: spy)

        trackForMemoryLeaks(spy)
        trackForMemoryLeaks(sut)
        return (sut, spy)
    }

    private func expect(sut: ExpirableCache<StorageSpy>, toCompleteWith expectedResult: Result<String, Swift.Error>, file: StaticString = #filePath, line: UInt = #line) {
        
        let exp = expectation(description: "Wait for async query to complete")
        sut.load { result in
            switch (result, expectedResult) {
            case let (.success(received), .success(expected)):
                XCTAssertEqual(received, expected, file: file, line: line)
            case let (.failure(received), .failure(expected)):
                XCTAssertEqual(received as NSError, expected as NSError, file: file, line: line)
            default:
                XCTFail("Expected \(expectedResult) got \(result) instead", file: file, line: line)
            }
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)
    }

}

private enum StorageSpyError: Swift.Error {
    case empty
}

private class StorageSpy: Storage, TimestampValidationPolicy {
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
    
    func load(completion: (Result<String, Error>) -> Void) {
        messages.append(.load)
        if let value {
            completion(.success(value))
        } else {
            completion(.failure(StorageSpyError.empty))
        }
    }
    
    func save(value: Stored, completion: (Error?) -> Void) {
        messages.append(.save(value))
        self.value = value
        completion(nil)
    }
    
    func clear(completion: (Error?) -> Void) {
        messages.append(.clear)
        value = nil
        completion(nil)
    }
    
    var isValid = true
    func validate(_ timestamp: Date?) -> Bool {
        messages.append(.validate(timestamp))
        return isValid
    }
}
