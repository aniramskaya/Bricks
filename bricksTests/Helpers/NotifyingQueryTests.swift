//
//  NotifyingQueryTests.swift
//  bricksTests
//
//  Created by Марина Чемезова on 12.05.2023.
//

import Foundation
import XCTest
import bricks

class NotifyingQuery<WrappedQuery: FailableQuery>: FailableQuery {
    typealias Success = WrappedQuery.Success
    typealias Failure = WrappedQuery.Failure
    
    let wrappee: WrappedQuery
    let onSuccess: ((Success) -> Void)?
    let onFailure: ((Failure) -> Void)?
    
    init(
        wrappee: WrappedQuery,
        onSuccess: ((Success) -> Void)? = nil,
        onFailure: ((Failure) -> Void)? = nil
    ) {
        self.wrappee = wrappee
        self.onSuccess = onSuccess
        self.onFailure = onFailure
    }
    
    func load(completion: @escaping (Result<Success, Failure>) -> Void) {
        wrappee.load { [weak self] result in
            guard let self else { return }
            switch result {
            case let .success(success):
                self.onSuccess?(success)
            default: ()
            }
            completion(result)
        }
    }
}

class NotifyingQueryTests: XCTestCase {
    func test_doesNotMessageUponCreation() throws {
        let (_, stub) = makeSUT(result: .success(UUID().uuidString))
        
        XCTAssertEqual(stub.messages, [])
    }
    
    func test_load_callsOnSuccessWhenLoadingSucceded() throws {
        let anyString = UUID().uuidString
        let (sut, stub) = makeSUT(result: .success(anyString))

        expect(sut: sut, toCompleteWith: .success(anyString))
        
        XCTAssertEqual(stub.messages, [.load, .success(anyString)])
    }
    
    private func makeSUT(result: Result<String, NSError>, file: StaticString = #filePath, line: UInt = #line) -> (NotifyingQuery<QueryStub>, QueryStub) {
        let stub = QueryStub(result: result)
        let sut =  NotifyingQuery(
            wrappee: stub,
            onSuccess: stub.onSuccess,
            onFailure: stub.onFailure
        )

        trackForMemoryLeaks(sut, file: file, line: line)
        trackForMemoryLeaks(stub, file: file, line: line)
        return (sut, stub)
    }
    
    private func expect(sut: NotifyingQuery<QueryStub>, toCompleteWith expectedResult: Result<String, NSError>, file: StaticString = #filePath, line: UInt = #line) {
        
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
        wait(for: [exp], timeout: 1.0)
    }

}

private class QueryStub: FailableQuery {
    typealias Success = String
    typealias Failure = NSError
    
    enum Message: Equatable {
        case load
        case success(Success)
        case failure(Failure)
    }
    
    var messages: [Message] = []
    
    var result: Result<Success, Failure>
    
    init(result: Result<Success, Failure>) {
        self.result = result
    }
    
    func load(completion: @escaping (Result<Success, Failure>) -> Void) {
        messages.append(.load)
        completion(result)
    }
    
    func onSuccess(_ value: Success) {
        messages.append(.success(value))
    }
    
    func onFailure(_ value: Failure) {
        messages.append(.failure(value))
    }
}
