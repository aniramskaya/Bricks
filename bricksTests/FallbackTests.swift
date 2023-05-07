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
    
    let primary: Primary
    let fallback: Secondary
    init(primary: Primary, fallback: Secondary) {
        self.primary = primary
        self.fallback = fallback
    }
    
    func load(_ completion: @escaping (_ result: Result<Success, Failure>) -> Void) {
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
