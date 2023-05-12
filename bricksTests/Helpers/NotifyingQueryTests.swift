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
        var onSuccessCallCount = 0
        var onFailureCallCount = 0
        let _ =  NotifyingQuery(
            wrappee: stub,
            onSuccess: { _ in onSuccessCallCount += 1},
            onFailure: { _ in onFailureCallCount += 1}
        )
        
        XCTAssertEqual(stub.loadCallCount, 0)
        XCTAssertEqual(onSuccessCallCount, 0)
        XCTAssertEqual(onFailureCallCount, 0)
    }
    
}

private class QueryStub: FailableQuery {
    typealias Success = String
    typealias Failure = Error

    var result: Result<Success, Failure>
    
    init(result: Result<Success, Failure>) {
        self.result = result
    }
    
    var loadCallCount = 0
    
    func load(completion: @escaping (Result<Success, Failure>) -> Void) {
        loadCallCount += 1
        completion(result)
    }
}
