//
//  SynchronizerTests.swift
//  bricksTests
//
//  Created by Марина Чемезова on 12.05.2023.
//

import Foundation
import XCTest
import bricks

class Synchronizer<Query1: Query, Query2: Query>: Query {
    typealias Result = (Query1.Result, Query2.Result)
    
    let query1: Query1
    let query2: Query2
    
    init(_ query1: Query1, _ query2: Query2) {
        self.query1 = query1
        self.query2 = query2
    }
    
    func load(completion: @escaping ((Query1.Result, Query2.Result)) -> Void) {
        
    }
}

class SynchronizerTests: XCTestCase {
    func test_synchronizer_doesNotMessageUponCreation() throws {
        let spy1 = QuerySpy()
        let spy2 = QuerySpy()
        let _ = Synchronizer(spy1, spy2)
        
        XCTAssertEqual(spy1.messages, [])
        XCTAssertEqual(spy2.messages, [])
    }
}

private class QuerySpy: FailableQuery {
    typealias Success = String
    typealias Failure = NSError
    
    enum Message: Equatable {
        case load
    }
    
    var messages: [Message] = []
    var completions: [(Result<Success, Failure>) -> Void] = []
    
    func load(completion: @escaping (Result<Success, Failure>) -> Void) {
        messages.append(.load)
        completions.append(completion)
    }
}
