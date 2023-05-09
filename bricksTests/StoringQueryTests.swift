//
//  StoringQueryTests.swift
//  bricksTests
//
//  Created by Марина Чемезова on 07.05.2023.
//

import Foundation
import XCTest
import bricks

class StoringQueryTests: XCTestCase {
    func test_sut_doesNotMessageUponCreation() throws {
        let (_, storageSpy, querySpy) = makeSUT()
        
        XCTAssertEqual(storageSpy.messages, [])
        XCTAssertEqual(querySpy.messages, [])
    }
    
    func test_load_deliversErrorOnWrappedQueryError() throws {
        let (sut, storageSpy, querySpy) = makeSUT()
        let error = NSError.any()

        expect(
            sut: sut,
            when: { storageSpy.completeLoading(with: .failure(error)) },
            toCompleteWith: .failure(error)
        )
        
        XCTAssertEqual(storageSpy.messages, [.loadQuery])
        XCTAssertEqual(querySpy.messages, [])
    }
 
    func test_load_deliversSuccessAndStoresOnWrappedQuerySuccess() throws {
        let (sut, storageSpy, querySpy) = makeSUT()
        let result = UUID().uuidString

        expect(
            sut: sut,
            when: { storageSpy.completeLoading(with: .success(result)) },
            toCompleteWith: .success(result)
        )
        
        XCTAssertEqual(storageSpy.messages, [.loadQuery])
        XCTAssertEqual(querySpy.messages, [.saveStorage(result)])
    }
    
    func test_load_doesNotCallCompletionWhenDeallocated() {
        var (sut, storageSpy, _): (StoringQuery<QuerySpy, StorageSpy>?, QuerySpy, StorageSpy)  = makeSUT()
        
        var completionCallCount = 0
        sut?.load { _ in
            completionCallCount += 1
        }
        sut = nil
        storageSpy.completeLoading(with: .failure(NSError.any()))
        
        XCTAssertEqual(storageSpy.messages, [.loadQuery,])
        XCTAssertEqual(completionCallCount, 0)
    }


    // MARK: Private
    
    private func makeSUT(file: StaticString = #filePath, line: UInt = #line) -> (StoringQuery<QuerySpy, StorageSpy>, QuerySpy, StorageSpy) {
        let querySpy = QuerySpy()
        let storageSpy = StorageSpy()
        let sut = StoringQuery(query: querySpy, storage: storageSpy)

        trackForMemoryLeaks(storageSpy, file: file, line: line)
        trackForMemoryLeaks(querySpy, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        return (sut, querySpy, storageSpy)
    }
    
    private func expect(sut: StoringQuery<QuerySpy, StorageSpy>, when action: () -> Void, toCompleteWith expectedResult: Result<String, NSError>, file: StaticString = #filePath, line: UInt = #line) {
        
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
        action()
        wait(for: [exp], timeout: 1.0)
    }
}

private class QuerySpy: FailableQuery {
    typealias Success = String
    typealias Failure = NSError
    
    enum Message: Equatable {
        case loadQuery
    }
    
    var messages: [Message] = []
    var completions: [(Result<String, NSError>) -> Void] = []
    
    func load(completion: @escaping (Result<String, NSError>) -> Void) {
        messages.append(.loadQuery)
        completions.append(completion)
    }
    
    func completeLoading(with result: Result<String, NSError>, at index: Int = 0) {
        completions[index](result)
    }
}

private class StorageSpy: Storage {
    enum Message: Equatable {
        case loadStorage
        case saveStorage(String)
        case clearStorage
    }
    
    var messages: [Message] = []

    var timestamp: Date?
    
    func load(completion: (Result<String, Error>) -> Void) {
        messages.append(.loadStorage)
        completion(.failure(NSError.any()))
    }
    
    func save(value: String, completion: (Error?) -> Void) {
        messages.append(.saveStorage(value))
        completion(nil)
    }
    
    func clear(completion: (Error?) -> Void) {
        messages.append(.clearStorage)
        completion(nil)
    }
}
