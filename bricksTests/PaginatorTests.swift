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
 
 Пагинатор
 
 Загружает список объектов постранично
 
 Имеет три метода: load, loadMore и reset
 Имеет состояние: уже загруженные страницы и флажок hasMore, показывающий что есть еще страницы
 
 Логика:
 
 Если загруженных данных нет, при вызове load или loadMore загружает первую страницу
 Если загруженные данные есть, при вызове load просто возвращает уже имеющиеся в памяти страницы
 Если загруженные данные есть, при вызове loadMore загружает следующую страницу, добавляет ее в конец уже имеющихся в памяти даных и возвращает обновленный вариант списка
 
 Вместе с данными всегда возвращает признак hasMore
 hasMore изначально имеет значение true и устанавливается в false если при загрузке страницы был получен пустой список

 Если есть загруженные данные, вызов reset удаляет сохраненные данные и сбрасывает hasMore в true

 При ошибке загрузки любой страницы возвращает ошибку
 
 Корнер кейсы (спорные, нужна помощь):
 
 Если вызван load или loadMore во время загрузки предыдущего вызова load или loadMore - не запускает выполнения нового запроса, а сохраняет completion и после завершения загрузки предыдущего вызова вызывает его, передавая полученные данные. Другими словами - повторные вызовы методов не влияют на уже выполняющуюся загрузку и завершаются с теми данными, которые были ею загружены.
 
 Если вызван reset во время выполнения вызова load или loadMore - отменяет текущую загрузку не вызывая completion.
 
 
 
 
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
 
 [✅] Test that paginator does not call completion when destroyed while loading
 [✅] Test that query created with builder does not disappear on leaving load method
 [✅] Test that paginator demultiplies multiple calls
 
 */
class Paginator<PageQuery: FailableQuery> where PageQuery.Success: Collection & Equatable {
    typealias Result = Swift.Result<(PageQuery.Success, Bool), PageQuery.Failure>
    let queryBuilder: () -> PageQuery
    
    init(queryBuilder: @escaping () -> PageQuery) {
        self.queryBuilder = queryBuilder
    }
    
    
    func load(_ completion: @escaping (Paginator.Result) -> Void) {
        if let loadedData {
            completion(.success(loadedData))
            return
        }
        completionsLock.lock()
        completions.append(completion)
        if inProgress == nil {
            let query = queryBuilder()
            inProgress = query
            query.load { [weak self] result in
                guard let self else { return }
                self.completeAll(with: result)
            }
        }
        completionsLock.unlock()
    }
    
    // MARK: - Private

    private var inProgress: PageQuery?
    private var completions: [(Paginator.Result) -> Void] = []
    private var completionsLock = NSRecursiveLock()
    private var loadedData: (PageQuery.Success, Bool)?

    private func completeAll(with loadedResult: PageQuery.Result) {
        completionsLock.lock()
        let captured = completions
        completions = []
        inProgress = nil
        completionsLock.unlock()
        let result = loadedResult.map { ($0, !$0.isEmpty) }
        loadedData = try? result.get()
        for item in captured {
            item(result)
        }
    }
}

class PaginatorTests: XCTestCase {
    private typealias PaginatorResult = Paginator<PagesLoaderSpy>.Result
    
    func test_init_doesNotSendAnyMessage() {
        var queryBuilderCallCount = 0
        let (_, spy) = makeSUT { spy in
            queryBuilderCallCount += 1
            return spy
        }

        XCTAssertEqual(queryBuilderCallCount, 0)
        XCTAssertEqual(spy.loadCallCount, 0)
    }
    
    func test_load_callsQueryBuilderAndQueryLoad() {
        var queryBuilderCallCount = 0
        let (sut, spy) = makeSUT { spy in
            queryBuilderCallCount += 1
            return spy
        }

        sut.load { _ in }
        
        XCTAssertEqual(queryBuilderCallCount, 1)
        XCTAssertEqual(spy.loadCallCount, 1)
    }
    
    func test_load_doesNotCallCompletionWhenSutIsDeallocated() {
        let spy = PagesLoaderSpy()
        var sut: Paginator<PagesLoaderSpy>? = Paginator { spy }

        sut?.load { _ in
            XCTFail("Paginator completion should not be called when Paginator is deallocated while loading")
        }
        sut = nil
        spy.complete(with: .success([UUID().uuidString]))
    }
    
    func test_load_guaranteesThatQueryDoesNotDestroyedUntilFinished() {
        let (sut, spy) = makeSUT { $0 }

        let items = [UUID().uuidString]
        let passedResult = PagesLoaderSpy.Result.success(items)
        let expectedResult = PaginatorResult.success((items, true))
        
        expect(sut, toCompleteWith: expectedResult) {
            spy.complete(with: passedResult)
        }
    }
    
    func test_load_demultipliesSerialCalls() {
        let (sut, spy) = makeSUT { $0 }

        let items = [UUID().uuidString]
        let passedResult = PagesLoaderSpy.Result.success(items)
        let expectedResult = PaginatorResult.success((items, true))

        expect(sut, toCompleteWith: expectedResult) {
            expect(sut, toCompleteWith: expectedResult) {
                spy.complete(with: passedResult)
            }
        }
        
        XCTAssertEqual(spy.loadCallCount, 1)
    }

    
    func test_load_deliversFailureOnFailure() {
        let (sut, spy) = makeSUT { $0 }

        let error = NSError.any()
        let passedResult = PagesLoaderSpy.Result.failure(error)
        let expectedResult = PaginatorResult.failure(error)
        
        expect(sut, toCompleteWith: expectedResult) {
            spy.complete(with: passedResult)
        }
        
        XCTAssertEqual(spy.loadCallCount, 1)
    }

    func test_pageLoading() {
        let (sut, spy) = makeSUT { $0 }

        let page1Items = [UUID().uuidString]
        
        // Loads page 1
        expect(sut, toCompleteWith: .success((page1Items, true))) {
            spy.complete(with: .success(page1Items))
        }

        // Retrieves loaded data without extra page loading
        expect(sut, toCompleteWith: .success((page1Items, true))) {
        }
        
        XCTAssertEqual(spy.loadCallCount, 1)
    }

    // MARK: - Private
    
    private func makeSUT<PageQuery: FailableQuery>(queryBuilder: @escaping (PagesLoaderSpy) -> PageQuery) -> (Paginator<PageQuery>, PagesLoaderSpy) {
        let spy = PagesLoaderSpy()
        let sut = Paginator(queryBuilder: { queryBuilder(spy) })

        return (sut, spy)
    }
    
    private func expect<PageQuery: FailableQuery>(
        _ sut: Paginator<PageQuery>,
        toCompleteWith expectedResult: Paginator<PageQuery>.Result,
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
