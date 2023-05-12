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
        
    }
}

class NotifyingQueryTests: XCTestCase {
    func test_doesNotMessageUponCreation() throws {
        let stub = QueryStub(result: .success("AnyString"))
        let _ =  NotifyingQuery(
            wrappee: stub,
            onSuccess: stub.onSuccess,
            onFailure: stub.onFailure
        )
        
        XCTAssertEqual(stub.messages, [])
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
