//
//  PaginatorTests.swift
//  bricksTests
//
//  Created by Марина Чемезова on 01.06.2023.
//

import Foundation
import XCTest
import bricks

/*
 Paginator needs some query to load data
 It might be created each time when load or loadMore is called
 
 Paginator scenarios
 
 Given: no data has been loaded yet
 When: load is called
 Then: loads first page data returning items and hasMore flag on success of error on failure

 Given: data has been loaded
 When: load is called
 Then: returns items from memory
 
 Given: data has been loaded
 When: loadMore is called
 Then: loads next page data returning items and hasMore flag on success of error on failure
 
 Given: data has been loaded
 When: reset is called
 Then: deletes loaded data
 
 */
class Paginator<PageQuery: FailableQuery> where PageQuery.Success: Collection {
    let queryBuilder: () -> PageQuery
    
    init(queryBuilder: @escaping () -> PageQuery) {
        self.queryBuilder = queryBuilder
    }
}

class PaginatorTests: XCTestCase {
    func test_init_doesNotSendAnyMessage() {
        var queryBuilderCallCount = 0
        let spy = PagesLoaderSpy()
        let _ = Paginator(queryBuilder: {
            queryBuilderCallCount += 1
            return spy
        })
        
        XCTAssertEqual(queryBuilderCallCount, 0)
        XCTAssertEqual(spy.loadCallCount, 0)
    }
}

class PagesLoaderSpy: FailableQuery {
    typealias Success = [String]
    typealias Failure = Swift.Error
    
    var loadCallCount = 0
    var completions: [(Result<Success, Failure>) -> Void] = []
    
    func load(completion: @escaping (Result<Success, Failure>) -> Void) {
        loadCallCount += 1
        completions.append(completion)
    }
    
    func complete(with result: (Result<Success, Failure>), at index: Int = 0) {
        completions[index](result)
    }
}
