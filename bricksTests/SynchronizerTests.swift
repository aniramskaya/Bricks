//
//  SynchronizerTests.swift
//  bricksTests
//
//  Created by Марина Чемезова on 12.05.2023.
//

import Foundation
import XCTest
import bricks

/// Executes two different ``Query`` in parallel and completes when both queries have completed
class Synchronizer<Query1: Query, Query2: Query>: Query {
    typealias Result = (Query1.Result, Query2.Result)
    
    let query1: Query1
    let query2: Query2
    let queue: DispatchQueue
    
    init(_ query1: Query1, _ query2: Query2) {
        queue = DispatchQueue(label: "Query Synchronizer Queue")
        self.query1 = query1
        self.query2 = query2
    }
    
    func load(completion: @escaping ((Query1.Result, Query2.Result)) -> Void) {
        let dispatchGroup = DispatchGroup()
        var result1: Query1.Result?
        var result2: Query2.Result?

        dispatchGroup.enter()
        dispatchGroup.enter()
        
        dispatchGroup.notify(queue: queue, work: DispatchWorkItem(block: { [weak self] in
            guard self != nil else { return }
            completion((result1!, result2!))
        }))
        
        query1.load {
            result in result1 = result
            dispatchGroup.leave()
        }
        query2.load {
            result in result2 = result
            dispatchGroup.leave()
        }
    }
}

class SynchronizerTests: XCTestCase {
    func test_synchronizer_doesNotMessageUponCreation() throws {
        let (_, spy1, spy2) = makeSUT()
        
        XCTAssertEqual(spy1.messages, [])
        XCTAssertEqual(spy2.messages, [])
    }
    
    func test_load_completesWhenBothQueriesComplete() throws {
        let (sut, spy1, spy2) = makeSUT()

        let result1 = UUID().uuidString
        let result2 = UUID().uuidString

        let exp = expectation(description: "Wait for loading to complete")
        var completionCount = 0
        sut.load { result in
            completionCount += 1
            XCTAssertEqual(result.0, result1)
            XCTAssertEqual(result.1, result2)
            exp.fulfill()
        }
        
        spy1.complete(with: result1)
        spy2.complete(with: result2)
        
        wait(for: [exp], timeout: 1.0)
     
        XCTAssertEqual(spy1.messages, [.load])
        XCTAssertEqual(spy2.messages, [.load])
        XCTAssertEqual(completionCount, 1)
    }
    
    func test_load_doesNotCallCompletionWhenSUTIsDeallocated() {
        let spy1 = QuerySpy()
        let spy2 = QuerySpy()
        var sut: Synchronizer<QuerySpy, QuerySpy>? = Synchronizer(spy1, spy2)

        var completionCallCount = 0
        sut?.load { _ in
            completionCallCount += 1
        }
        
        sut = nil
        spy1.complete(with: "qwe")
        spy2.complete(with: "asd")
        
        RunLoop.main.run(until: Date())
        
        XCTAssertEqual(completionCallCount, 0)
    }
    
    private func makeSUT(file: StaticString = #filePath, line: UInt = #line) -> (Synchronizer<QuerySpy, QuerySpy>, QuerySpy, QuerySpy) {
        let spy1 = QuerySpy()
        let spy2 = QuerySpy()
        let sut = Synchronizer(spy1, spy2)

        trackForMemoryLeaks(sut, file: file, line: line)
        trackForMemoryLeaks(spy1, file: file, line: line)
        trackForMemoryLeaks(spy2, file: file, line: line)

        return (sut, spy1, spy2)
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
