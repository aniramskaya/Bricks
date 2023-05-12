//
//  NotifyingQueryTests.swift
//  bricksTests
//
//  Created by Марина Чемезова on 12.05.2023.
//

import Foundation
import XCTest
import bricks


class NotifyingQueryTests: XCTestCase {
    func test_doesNotMessageUponCreation() throws {
        let (_, stub) = makeSUT()
        
        XCTAssertEqual(stub.messages, [])
    }
    
    func test_load_callsOnSuccessWhenLoadingSucceded() throws {
        let anyString = UUID().uuidString
        let (sut, spy) = makeSUT()

        expect(
            sut: sut,
            when: { spy.complete(with: .success(anyString))  },
            toCompleteWith: .success(anyString)
        )
        
        XCTAssertEqual(spy.messages, [.load, .success(anyString)])
    }

    func test_load_callsOnFailureWhenLoadingFailed() throws {
        let error = NSError.any()
        let (sut, spy) = makeSUT()

        expect(
            sut: sut,
            when: { spy.complete(with: .failure(error))},
            toCompleteWith: .failure(error)
        )
        
        XCTAssertEqual(spy.messages, [.load, .failure(error)])
    }

    func test_load_doesNotCallCompletionWhenDeallocated() throws {
        let spy = QuerySpy()
        var onSuccessCallCount = 0
        var onFailureCallCount = 0
        var sut: NotifyingQuery<QuerySpy>? =  NotifyingQuery(
            wrappee: spy,
            onSuccess: { _ in onSuccessCallCount += 1},
            onFailure: { _ in onFailureCallCount += 1}
        )
        
        sut?.load{ _ in }
        sut = nil
        spy.complete(with: .success(""))
        
        RunLoop.main.run(until: Date())

        XCTAssertEqual(spy.messages, [.load])
    }

    private func makeSUT(file: StaticString = #filePath, line: UInt = #line) -> (NotifyingQuery<QuerySpy>, QuerySpy) {
        let spy = QuerySpy()
        let sut =  NotifyingQuery(
            wrappee: spy,
            onSuccess: spy.onSuccess,
            onFailure: spy.onFailure
        )

        trackForMemoryLeaks(sut, file: file, line: line)
        trackForMemoryLeaks(spy, file: file, line: line)
        return (sut, spy)
    }
    
    private func expect(sut: NotifyingQuery<QuerySpy>, when action: () -> Void, toCompleteWith expectedResult: Result<String, NSError>, file: StaticString = #filePath, line: UInt = #line) {
        
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
        case load
        case success(Success)
        case failure(Failure)
    }
    
    var messages: [Message] = []
    var completions: [(Result<Success, Failure>) -> Void] = []
    
    func load(completion: @escaping (Result<Success, Failure>) -> Void) {
        messages.append(.load)
        completions.append(completion)
    }
    
    func complete(with result: Result<Success, Failure>, at index: Int = 0) {
        completions[index](result)
    }
    
    func onSuccess(_ value: Success) {
        messages.append(.success(value))
    }
    
    func onFailure(_ value: Failure) {
        messages.append(.failure(value))
    }
}
