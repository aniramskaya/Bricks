//
//  StoringQueryTests.swift
//  bricksTests
//
//  Created by Марина Чемезова on 07.05.2023.
//

import Foundation
import XCTest
import bricks

class StoringQuery<Success, Failure: Error, WrappedQuery: FailableQuery, Storage: SynchronousStorage>: FailableQuery
where WrappedQuery.Success == Success, WrappedQuery.Failure == Failure, Storage.Stored == Success
{
    var query: WrappedQuery
    var storage: Storage
    
    init(query: WrappedQuery, storage: Storage) {
        self.query = query
        self.storage = storage
    }
    
    func load(_ completion: @escaping (WrappedQuery.Result) -> Void) {
        query.load { _ in
        }
    }
    
}

class StoringQueryTests: XCTestCase {
    func test_sut_doesNotMessageUponCreation() throws {
        let spy = QuerySpy()
        let sut = StoringQuery(query: spy, storage: spy)
        
        XCTAssertEqual(spy.messages, [])
    }
    
    
}

private class QuerySpy: FailableQuery, SynchronousStorage {
    typealias Success = String
    typealias Failure = NSError
    
    enum Message: Equatable {
        case loadQuery
        case loadStorage
        case saveStorage(String)
        case clearStorage
    }
    
    var messages: [Message] = []
    var completions: [(Result<String, NSError>) -> Void] = []
    
    func load(_ completion: @escaping (Result<String, NSError>) -> Void) {
        messages.append(.loadQuery)
        completions.append(completion)
    }
    
    func completeLoading(with result: Result<String, NSError>, at index: Int = 0) {
        completions[index](result)
    }
    
    func load() -> String? {
        messages.append(.loadStorage)
        return nil
    }
    
    func save(_ value: String) {
        messages.append(.saveStorage(value))
    }
    
    func clear() {
        messages.append(.clearStorage)
    }
}
