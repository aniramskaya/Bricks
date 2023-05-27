//
//  DemultiplyerTests.swift
//  bricksTests
//
//  Created by Марина Чемезова on 12.05.2023.
//

import Foundation
import XCTest
import bricks

/// ``FailableQuery`` which aggregates multiple loads calls during loading and calls all completions when loading finished
public final class DemultiplyingQuery<WrappedQuery: Query>: Query
{
    public typealias Result = WrappedQuery.Result
    
    private var query: WrappedQuery
    private var completions: [(WrappedQuery.Result) -> Void] = []
    private var completionsLock = NSRecursiveLock()
    
    
    /// Designated initializer.
    ///
    /// - Parameters:
    ///   - query: Query to wrap
    public init(query: WrappedQuery) {
        self.query = query
    }
    
    /// Loads data from `query` passed in initializer and if it succeeded saves it into `storage`
    ///
    /// > Impotant: Method does not care about waiting for saving result and checking it. All saving errors are discarded.
    /// - Parameters:
    ///   - completion: A closure which is called when the loading process has complete.
    public func load(completion: @escaping (Result) -> Void) {
        if add(completion) {
            query.load { [weak self] result in
                self?.completeAll(with: result)
            }
        }
    }
    
    // MARK: - Private

    private func add(_ completion: @escaping (Result) -> Void) -> Bool {
        completionsLock.lock()
        let isFirstCompletion = completions.isEmpty
        completions.append(completion)
        completionsLock.unlock()
        return isFirstCompletion
    }
    
    private func completeAll(with result: Result) {
        completionsLock.lock()
        let captured = completions
        completions = []
        completionsLock.unlock()
        for item in captured {
            item(result)
        }
    }
}

class DemultiplyerTests: XCTestCase {
    func test_synchronizer_doesNotMessageUponCreation() throws {
        let (_, spy) = makeSUT()
        
        XCTAssertEqual(spy.messages, [])
    }
    
    func test_multipleLoad_turnsIntoSingle() throws {
        let (sut, spy) = makeSUT()

        let expectedResult = UUID().uuidString

        let exp = expectation(description: "Wait for loading to complete")
        exp.expectedFulfillmentCount = 2
        DispatchQueue.global(qos: .background).async {
            sut.load { result in
                XCTAssertEqual(result, expectedResult)
            }
            exp.fulfill()
        }
        DispatchQueue.global(qos: .background).async {
            sut.load { result in
                XCTAssertEqual(result, expectedResult)
            }
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)
        spy.complete(with: expectedResult)
        
        XCTAssertEqual(spy.messages, [.load])
    }
    
    func test_load_doesNotCallCompletionWhenSUTIsDeallocated() {
        let spy = QuerySpy()
        var sut: DemultiplyingQuery<QuerySpy>? = DemultiplyingQuery(query: spy)

        var completionCallCount = 0
        sut?.load { _ in
            completionCallCount += 1
        }
        
        sut = nil
        spy.complete(with: "qwe")
        
        RunLoop.main.run(until: Date())
        
        XCTAssertEqual(completionCallCount, 0)
    }
    
    private func makeSUT(file: StaticString = #filePath, line: UInt = #line) -> (DemultiplyingQuery<QuerySpy>, QuerySpy) {
        let spy = QuerySpy()
        let sut = DemultiplyingQuery(query: spy)

        trackForMemoryLeaks(sut, file: file, line: line)

        return (sut, spy)
    }
}

private class QuerySpy: Query {
    typealias Result = String
    
    enum Message: Equatable {
        case load
    }
    
    var messages: [Message] = []
    var completions: [(String) -> Void] = []
    
    func load(completion: @escaping (String) -> Void) {
        messages.append(.load)
        completions.append(completion)
    }
    
    func complete(with result: String, at index: Int = 0) {
        completions[index](result)
    }
}
