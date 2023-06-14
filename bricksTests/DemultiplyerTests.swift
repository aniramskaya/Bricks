//
//  DemultiplyerTests.swift
//  bricksTests
//
//  Created by Марина Чемезова on 12.05.2023.
//

import Foundation
import XCTest
import bricks

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
        sut.load { result in
            XCTAssertEqual(result, expectedResult)
            exp.fulfill()
        }
        sut.load { result in
            XCTAssertEqual(result, expectedResult)
            exp.fulfill()
        }
        spy.complete(with: expectedResult)
        wait(for: [exp], timeout: 1.0)
        
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
