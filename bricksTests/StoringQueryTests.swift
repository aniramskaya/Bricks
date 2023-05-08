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
        let (_, spy) = makeSUT()
        
        XCTAssertEqual(spy.messages, [])
    }
    
    func test_load_deliversErrorOnWrappedQueryError() throws {
        let (sut, spy) = makeSUT()
        let error = NSError.any()

        expect(
            sut: sut,
            when: { spy.completeLoading(with: .failure(error)) },
            toCompleteWith: .failure(error)
        )
        
        XCTAssertEqual(spy.messages, [.loadQuery])
    }
 
    func test_load_deliversSuccessAndStoresOnWrappedQuerySuccess() throws {
        let (sut, spy) = makeSUT()
        let result = UUID().uuidString

        expect(
            sut: sut,
            when: { spy.completeLoading(with: .success(result)) },
            toCompleteWith: .success(result)
        )
        
        XCTAssertEqual(spy.messages, [.loadQuery, .saveStorage(result)])
    }
    
    func test_load_doesNotCallCompletionWhenDeallocated() {
        var (sut, spy): (StoringQuery<QuerySpy, QuerySpy>?, QuerySpy)  = makeSUT()
        
        var completionCallCount = 0
        sut?.load { _ in
            completionCallCount += 1
        }
        sut = nil
        spy.completeLoading(with: .failure(NSError.any()))
        
        XCTAssertEqual(spy.messages, [.loadQuery,])
        XCTAssertEqual(completionCallCount, 0)
    }


    // MARK: Private
    
    private func makeSUT(file: StaticString = #filePath, line: UInt = #line) -> (StoringQuery<QuerySpy, QuerySpy>, QuerySpy) {
        let spy = QuerySpy()
        let sut = StoringQuery(query: spy, storage: spy)

        trackForMemoryLeaks(spy, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        return (sut, spy)
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
    
    func load(completion: @escaping (Result<String, NSError>) -> Void) {
        messages.append(.loadQuery)
        completions.append(completion)
    }
    
    func completeLoading(with result: Result<String, NSError>, at index: Int = 0) {
        completions[index](result)
    }
    
    var timestamp: Date?
    
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
