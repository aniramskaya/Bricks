//
//  PaginatorTests.swift
//  bricksTests
//
//  Created by Марина Чемезова on 01.06.2023.
//

import Foundation
import XCTest
import bricks

class PaginatorTests: XCTestCase {
    private typealias PaginatorResult = Paginator<PagesLoaderSpy>.Result
    
    func test_init_doesNotSendAnyMessage() {
        var queryBuilderCallCount = 0
        let (_, spy) = makeSUT { spy, _ in
            queryBuilderCallCount += 1
            return spy
        }

        XCTAssertEqual(queryBuilderCallCount, 0)
        XCTAssertEqual(spy.loadCallCount, 0)
    }
    
    func test_load_callsQueryBuilderAndQueryLoad() {
        var queryBuilderCallCount = 0
        let (sut, spy) = makeSUT { spy, _ in
            queryBuilderCallCount += 1
            return spy
        }

        sut.load { _ in }
        
        XCTAssertEqual(queryBuilderCallCount, 1)
        XCTAssertEqual(spy.loadCallCount, 1)
    }
    
    func test_load_doesNotCallCompletionWhenSutIsDeallocated() {
        let spy = PagesLoaderSpy()
        var sut: Paginator<PagesLoaderSpy>? = Paginator { _ in spy }

        sut?.load { _ in
            XCTFail("Paginator completion should not be called when Paginator is deallocated while loading")
        }
        sut = nil
        spy.complete(with: .success([UUID().uuidString]))
    }
    
    func test_load_guaranteesThatQueryDoesNotDestroyedUntilFinished() {
        let (sut, spy) = makeSUT { spy, _ in return spy }

        let items = [UUID().uuidString]
        let passedResult = PagesLoaderSpy.Result.success(items)
        let expectedResult = PaginatorResult.success((items, true))
        
        expect(sut, toLoadWith: expectedResult) {
            spy.complete(with: passedResult)
        }
    }
    
    func test_load_demultipliesSerialCalls() {
        let (sut, spy) = makeSUT { spy, _ in return spy }

        let items = [UUID().uuidString]
        let passedResult = PagesLoaderSpy.Result.success(items)
        let expectedResult = PaginatorResult.success((items, true))

        expect(sut, toLoadWith: expectedResult) {
            expect(sut, toLoadWith: expectedResult) {
                spy.complete(with: passedResult)
            }
        }
        
        XCTAssertEqual(spy.loadCallCount, 1)
    }

    
    func test_load_deliversFailureOnFailure() {
        let (sut, spy) = makeSUT { spy, _ in return spy }

        let error = NSError.any()
        let passedResult = PagesLoaderSpy.Result.failure(error)
        let expectedResult = PaginatorResult.failure(error)
        
        expect(sut, toLoadWith: expectedResult) {
            spy.complete(with: passedResult)
        }
        
        XCTAssertEqual(spy.loadCallCount, 1)
    }

    func test_pageLoading() {
        var requestedPages: [Int] = []
        
        // sut = System Under Test = Paginator
        // spy = Data loader test mock
        let (sut, spy) = makeSUT { spy, pageNumber in
            requestedPages.append(pageNumber)
            return spy
        }

        let page1Items = [UUID().uuidString]
        
        // Loads page 1 - returns page 1 with hasMore = true
        expect(sut, toLoadWith: .success((page1Items, true))) {
            spy.complete(with: .success(page1Items))
        }
        
        XCTAssertEqual(requestedPages, [1])

        // Retrieves in-memoкy data without any page loading
        expect(sut, toLoadWith: .success((page1Items, true))) {
        }
        
        let page2Items = [UUID().uuidString]
        
        // Loads page 2 - returns page 1 and page2 with hasMore = true
        expect(sut, toLoadMoreWith: .success((page1Items + page2Items, true))) {
            spy.complete(with: .success(page2Items), at: 1)
        }

        XCTAssertEqual(requestedPages, [1, 2])

        // Fails to load page 3 - returns error
        let page3Error = NSError.any()
        expect(sut, toLoadMoreWith: .failure(page3Error)) {
            spy.complete(with: .failure(page3Error), at: 2)
        }

        XCTAssertEqual(requestedPages, [1, 2, 3])

        // Loads page 3 (empty one) - returns page 1 and page2 with hasMore = false
        expect(sut, toLoadMoreWith: .success((page1Items + page2Items, false))) {
            spy.complete(with: .success([]), at: 3)
        }

        XCTAssertEqual(requestedPages, [1, 2, 3, 3])

        sut.reset()
        
        // Loads page 1 again
        // We also ensure that load and loadMore are equivalent for the first page
        expect(sut, toLoadMoreWith: .success((page1Items, true))) {
            spy.complete(with: .success(page1Items))
        }
        
        XCTAssertEqual(requestedPages, [1, 2, 3, 3, 1])
    }

    // MARK: - Private
    
    private func makeSUT<PageQuery: FailableQuery>(
        queryBuilder: @escaping (PagesLoaderSpy, Int) -> PageQuery,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> (Paginator<PageQuery>, PagesLoaderSpy) {
        let spy = PagesLoaderSpy()
        let sut = Paginator(queryBuilder: { pageNumber in queryBuilder(spy, pageNumber) }, firstPageNumber: 1)

        trackForMemoryLeaks(spy, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        return (sut, spy)
    }
    
    private func expect<PageQuery: FailableQuery>(
        _ sut: Paginator<PageQuery>,
        toLoadWith expectedResult: Paginator<PageQuery>.Result,
        when action: () -> Void,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let exp = expectation(description: "Wait for async to be loaded")
        sut.load { [weak self] result in
            self?.assertResultEqual(loaded: result, expected: expectedResult, file: file, line: line)
            exp.fulfill()
        }
        action()
        wait(for: [exp], timeout: 1.0)
    }

    private func expect<PageQuery: FailableQuery>(
        _ sut: Paginator<PageQuery>,
        toLoadMoreWith expectedResult: Paginator<PageQuery>.Result,
        when action: () -> Void,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let exp = expectation(description: "Wait for async to be loaded")
        sut.loadMore { [weak self] result in
            self?.assertResultEqual(loaded: result, expected: expectedResult, file: file, line: line)
            exp.fulfill()
        }
        action()
        wait(for: [exp], timeout: 1.0)
    }

    private func assertResultEqual<Success, Failure>(
        loaded: Result<(Success, Bool), Failure>,
        expected: Result<(Success, Bool), Failure>,
        file: StaticString = #filePath,
        line: UInt = #line
    ) where Success: Equatable, Failure: Error {
        switch (loaded, expected) {
        case let (.success(loaded), .success(expected)):
            XCTAssertEqual(loaded.0, expected.0, "Expected to load \(expected.0) got \(loaded.0) instead", file: file, line: line)
            XCTAssertEqual(loaded.1, expected.1, "Expected hasMore to be \(expected.1) got \(loaded.1) instead", file: file, line: line)
        case let (.failure(loaded), .failure(expected)):
            XCTAssertEqual(loaded as NSError, expected as NSError, "Expected to load \(expected) got \(loaded) instead", file: file, line: line)
        default:
            XCTFail("Expected to load \(expected) got \(loaded) instead", file: file, line: line)
        }

    }
}

class PagesLoaderSpy: ListFailableQuery {
    typealias Element = String
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
