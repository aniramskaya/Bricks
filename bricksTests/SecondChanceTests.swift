//
//  SecondChanceTests.swift
//  bricksTests
//
//  Created by Марина Чемезова on 07.05.2023.
//

import Foundation
import XCTest
import bricks

class SecondChanceTests: XCTestCase {
    func test_secondChance_doesNotMessageUponCreation() throws {
        let primary = QuerySpy()
        let secondary = QuerySpy()
        
        let _ = SecondChance(primary: primary, secondary: secondary)
        
        XCTAssertEqual(primary.messages, [])
        XCTAssertEqual(secondary.messages, [])
    }
    
    func test_load_whenBothFailed_deliversPrimaryError() throws {
        let (sut, primary, secondary) = makeSUT()
        let primaryError = NSError.any()
        let secondaryError = NSError.any()

        expect(
            sut: sut,
            when: {
                primary.completeLoading(with: .failure(primaryError))
                secondary.completeLoading(with: .failure(secondaryError))
            },
            toCompleteWith: .failure(primaryError)
        )
        
        XCTAssertEqual(primary.messages, [.load])
        XCTAssertEqual(secondary.messages, [.load])
    }
    
    func test_load_whenPrimaryFailedSecondarySucceed_deliversSecondarySuccess() throws {
        let (sut, primary, secondary) = makeSUT()
        let primaryError = NSError.any()
        let secondaryResult = UUID().uuidString

        expect(
            sut: sut,
            when: {
                primary.completeLoading(with: .failure(primaryError))
                secondary.completeLoading(with: .success(secondaryResult))
            },
            toCompleteWith: .success(secondaryResult)
        )

        XCTAssertEqual(primary.messages, [.load])
        XCTAssertEqual(secondary.messages, [.load])
    }

    func test_load_whenPrimarySucceed_deliversPrimarySuccess() throws {
        let (sut, primary, secondary) = makeSUT()
        let primaryResult = UUID().uuidString

        expect(
            sut: sut,
            when: {
                primary.completeLoading(with: .success(primaryResult))
            },
            toCompleteWith: .success(primaryResult)
        )
        
        XCTAssertEqual(primary.messages, [.load])
        XCTAssertEqual(secondary.messages, [])
    }
    
    func test_load_doesNotCallCompletionOnPrimaryWhenDeallocated() {
        var (sut, spy, secondary): (SecondChance<QuerySpy, QuerySpy>?, QuerySpy, _)  = makeSUT()
        
        var completionCallCount = 0
        sut?.load { _ in
            completionCallCount += 1
        }
        sut = nil
        spy.completeLoading(with: .success(UUID().uuidString))
        
        RunLoop.main.run(until: Date())

        XCTAssertEqual(spy.messages, [.load])
        XCTAssertEqual(secondary.messages, [])
        XCTAssertEqual(completionCallCount, 0)
    }

    func test_load_doesNotCallCompletionOnSecondaryWhenDeallocated() {
        var (sut, primary, secondary): (SecondChance<QuerySpy, QuerySpy>?, QuerySpy, QuerySpy)  = makeSUT()
        
        var completionCallCount = 0
        sut?.load { _ in
            completionCallCount += 1
        }
        primary.completeLoading(with: .failure(NSError.any()))
        sut = nil
        secondary.completeLoading(with: .success(UUID().uuidString))
        
        RunLoop.main.run(until: Date())

        XCTAssertEqual(primary.messages, [.load])
        XCTAssertEqual(secondary.messages, [.load])
        XCTAssertEqual(completionCallCount, 0)
    }

    private func expect(sut: SecondChance<QuerySpy, QuerySpy>, when action: () -> Void, toCompleteWith expectedResult: Result<String, NSError>, file: StaticString = #filePath, line: UInt = #line) {
        
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
    
    // MARK: Private
    
    private func makeSUT(file: StaticString = #filePath, line: UInt = #line) -> (SecondChance<QuerySpy, QuerySpy>, QuerySpy, QuerySpy) {
        let primary = QuerySpy()
        let secondary = QuerySpy()
        let sut = SecondChance(primary: primary, secondary: secondary)
        
        trackForMemoryLeaks(primary, file: file, line: line)
        trackForMemoryLeaks(secondary, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        return (sut, primary, secondary)
    }
}

private class QuerySpy: FailableQuery {
    typealias Success = String
    typealias Failure = NSError
    
    enum Message: Equatable {
        case load
    }
    
    var messages: [Message] = []
    var completions: [(Result<String, NSError>) -> Void] = []
    
    func load(completion: @escaping (Result<String, NSError>) -> Void) {
        messages.append(.load)
        completions.append(completion)
    }
    
    func completeLoading(with result: Result<String, NSError>, at index: Int = 0) {
        completions[index](result)
    }
}
