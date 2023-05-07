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
            default: break
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
        let primary = QuerySpy()
        let fallback = QuerySpy()
        let primaryError = NSError.any()
        let fallbackError = NSError.any()

        let sut = Fallback(primary: primary, fallback: fallback)
        expect(
            sut: sut,
            when: {
                primary.completeLoading(with: .failure(primaryError))
                fallback.completeLoading(with: .failure(fallbackError))
            },
            toCompleteWith: .failure(fallbackError)
        )
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
