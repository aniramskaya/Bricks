//
//  StoringQueryTests.swift
//  bricksTests
//
//  Created by Марина Чемезова on 07.05.2023.
//

import Foundation
import XCTest
import bricks

class StoringQuery<WrappedQuery: FailableQuery, Storage: SynchronousStorage>: FailableQuery where Storage.Stored == WrappedQuery.Success
{
    typealias Success = WrappedQuery.Success
    typealias Failure = WrappedQuery.Failure
    typealias Result = WrappedQuery.Result
    
    var query: WrappedQuery
    var storage: Storage
    
    init(query: WrappedQuery, storage: Storage) {
        self.query = query
        self.storage = storage
    }
    
    func load(_ completion: @escaping (WrappedQuery.Result) -> Void) {
        query.load { [weak self] result in
            guard let self else { return }
            if let value = try? result.get() {
                self.storage.save(value)
            }
            completion(result)
        }
    }
}

class StoringQueryTests: XCTestCase {
    func test_sut_doesNotMessageUponCreation() throws {
        let (_, spy) = makeSUT()
        
        XCTAssertEqual(spy.messages, [])
    }
    
    func test_sut_deliversErrorOnWrappedQueryError() throws {
        let (sut, spy) = makeSUT()
        let error = anyNSError()

        expect(
            sut: sut,
            when: { spy.completeLoading(with: .failure(error)) },
            toCompleteWith: .failure(error)
        )
        
        XCTAssertEqual(spy.messages, [.loadQuery])
    }
 
    func test_sut_deliversSuccessAndStoresOnWrappedQuerySuccess() throws {
        let (sut, spy) = makeSUT()
        let result = UUID().uuidString

        expect(
            sut: sut,
            when: { spy.completeLoading(with: .success(result)) },
            toCompleteWith: .success(result)
        )
        
        XCTAssertEqual(spy.messages, [.loadQuery, .saveStorage(result)])
    }

    // MARK: Private
    
    private func makeSUT() -> (StoringQuery<QuerySpy, QuerySpy>, QuerySpy) {
        let spy = QuerySpy()
        let sut = StoringQuery(query: spy, storage: spy)

        return (sut, spy)
    }
    
    private func anyNSError() -> NSError {
        return NSError(domain: UUID().uuidString, code: Int.random(in: 1...1000))
    }
    
    private func expect(sut: StoringQuery<QuerySpy, QuerySpy>, when action: () -> Void, toCompleteWith expectedResult: Result<String, NSError>, file: StaticString = #filePath, line: UInt = #line) {
        
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

private class QuerySpy: FailableQuery, SynchronousStorage {
    typealias Success = String
    typealias Failure = NSError
    
    enum Message: Equatable {
        case loadQuery
        case loadStorage
        case saveStorage(String)
        case clearStorage
    }
    
    var messages: [Message] = []
    var completions: [(Result<String, NSError>) -> Void] = []
    
    func load(_ completion: @escaping (Result<String, NSError>) -> Void) {
        messages.append(.loadQuery)
        completions.append(completion)
    }
    
    func completeLoading(with result: Result<String, NSError>, at index: Int = 0) {
        completions[index](result)
    }
    
    func load() -> String? {
        messages.append(.loadStorage)
        return nil
    }
    
    func save(_ value: String) {
        messages.append(.saveStorage(value))
    }
    
    func clear() {
        messages.append(.clearStorage)
    }
}
