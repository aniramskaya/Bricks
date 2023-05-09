//
//  SynchronousStorageAdapter.swift
//  bricksTests
//
//  Created by Марина Чемезова on 09.05.2023.
//

import Foundation
import XCTest
import bricks

enum StorageError: Error {
    case empty
}

class SynchronousStorageAdapter<WrappedStorage: SynchronousStorage>: Storage {
    typealias Stored = WrappedStorage.Stored
    
    let wrappee: WrappedStorage
    init(wrappee: WrappedStorage) {
        self.wrappee = wrappee
    }
    
    var timestamp: Date? { wrappee.timestamp }
    
    func load(completion: (Result<Stored, Error>) -> Void) {
        let _ = wrappee.load()
        completion(.failure(StorageError.empty))
    }
    
    func save(value: WrappedStorage.Stored, completion: (Error?) -> Void) {
        
    }

    func clear(completion: (Error?) -> Void) {
        
    }
}

class SynchronousStorageAdapterTests: XCTestCase {
    func test_adapter_doesNotMessageUponCreation() throws {
        let (_, spy) = makeSUT()
        
        XCTAssertEqual(spy.messages, [])
    }
    
    func test_timestamp_callsWrappeeTimestamp() throws {
        let (sut, spy) = makeSUT()

        let _ = sut.timestamp
        
        XCTAssertEqual(spy.messages, [.timestampRead])
    }
    
    func test_load_deliversErrorOnEmptyCache() throws {
        let (sut, spy) = makeSUT()

        expect(sut: sut, toCompleteWith: .failure(StorageError.empty))
        
        XCTAssertEqual(spy.messages, [.load])
    }
    
    private func makeSUT() -> (SynchronousStorageAdapter<SynchronousStorageSpy>, SynchronousStorageSpy) {
        let spy = SynchronousStorageSpy()
        let sut = SynchronousStorageAdapter(wrappee: spy)
        
        return (sut, spy)
    }
    
    private func expect(sut: SynchronousStorageAdapter<SynchronousStorageSpy>, toCompleteWith expectedResult: Result<String, Error>, file: StaticString = #filePath, line: UInt = #line) {
        
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
