//
//  FallbackTests.swift
//  bricksTests
//
//  Created by Марина Чемезова on 07.05.2023.
//

import Foundation
import XCTest
import bricks

class Fallback<Primary: FailableQuery, Secondary: FailableQuery>: FailableQuery
    where Primary.Success == Secondary.Success,
        Primary.Failure == Secondary.Failure
{
    typealias Success = Primary.Success
    typealias Failure = Primary.Failure
    
    private let primary: Primary
    private let fallback: Secondary
    
    init(primary: Primary, fallback: Secondary) {
        self.primary = primary
        self.fallback = fallback
    }
    
    func load(_ completion: @escaping (_ result: Result<Success, Failure>) -> Void) {
        primary.load {[unowned self] result in
            switch result {
            case .failure:
                self.fallback.load(completion)
            default:
                completion(result)
            }
        }
    }
}

class FallbackTests: XCTestCase {
    func test_fallback_doesNotMessageUponCreation() throws {
        let primary = QuerySpy()
        let fallback = QuerySpy()
        
        let _ = Fallback(primary: primary, fallback: fallback)
        
        XCTAssertEqual(primary.messages, [])
        XCTAssertEqual(fallback.messages, [])
    }
    
    func test_load_whenBothFailed_deliversFallbackError() throws {
        let (sut, primary, fallback) = makeSUT()
        let primaryError = NSError.any()
        let fallbackError = NSError.any()

        expect(
            sut: sut,
            when: {
                primary.completeLoading(with: .failure(primaryError))
                fallback.completeLoading(with: .failure(fallbackError))
            },
            toCompleteWith: .failure(fallbackError)
        )
        
        XCTAssertEqual(primary.messages, [.load])
        XCTAssertEqual(fallback.messages, [.load])
    }
    
    func test_load_whenPrimaryFailedFallbackSucceed_deliversFallbackSuccess() throws {
        let (sut, primary, fallback) = makeSUT()
        let primaryError = NSError.any()
        let fallbackResult = UUID().uuidString

        expect(
            sut: sut,
            when: {
                primary.completeLoading(with: .failure(primaryError))
                fallback.completeLoading(with: .success(fallbackResult))
            },
            toCompleteWith: .success(fallbackResult)
        )

        XCTAssertEqual(primary.messages, [.load])
        XCTAssertEqual(fallback.messages, [.load])
    }

    func test_load_whenPrimarySucceed_deliversPrimarySuccess() throws {
        let (sut, primary, fallback) = makeSUT()
        let primaryResult = UUID().uuidString

        expect(
            sut: sut,
            when: {
                primary.completeLoading(with: .success(primaryResult))
            },
            toCompleteWith: .success(primaryResult)
        )
        
        XCTAssertEqual(primary.messages, [.load])
        XCTAssertEqual(fallback.messages, [])
    }

    private func expect(sut: Fallback<QuerySpy, QuerySpy>, when action: () -> Void, toCompleteWith expectedResult: Result<String, NSError>, file: StaticString = #filePath, line: UInt = #line) {
        
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
    
    private func makeSUT() -> (Fallback<QuerySpy, QuerySpy>, QuerySpy, QuerySpy) {
        let primary = QuerySpy()
        let fallback = QuerySpy()
        let sut = Fallback(primary: primary, fallback: fallback)
        
        return (sut, primary, fallback)
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
    
    func load(_ completion: @escaping (Result<String, NSError>) -> Void) {
        messages.append(.load)
        completions.append(completion)
    }
    
    func completeLoading(with result: Result<String, NSError>, at index: Int = 0) {
        completions[index](result)
    }
}
