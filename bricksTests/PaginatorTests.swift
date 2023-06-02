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
 [] Test that query created with builder does not disappear on leaving load method
 [] Test that paginator demultiplies multiple calls
 
 */
class Paginator<PageQuery: FailableQuery> where PageQuery.Success: Collection {
    let queryBuilder: () -> PageQuery
    
    init(queryBuilder: @escaping () -> PageQuery) {
        self.queryBuilder = queryBuilder
    }
    
    private var inProgress: PageQuery?
    
    func load(_ completion: @escaping (Result<PageQuery.Success, PageQuery.Failure>) -> Void) {
        let query = inProgress ?? queryBuilder()
        inProgress = query
        query.load { [weak self] result in
            guard let self else { return }
            self.inProgress = nil
            completion(result)
        }
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
    
    func test_load_callsQueryBuilderAndQueryLoad() {
        var queryBuilderCallCount = 0
        let spy = PagesLoaderSpy()
        let sut = Paginator(queryBuilder: {
            queryBuilderCallCount += 1
            return spy
        })

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
        let spy = PagesLoaderSpy()
        let sut = Paginator(queryBuilder: {
            return spy.map(with: { $0 })
        })

        let passedResult = PagesLoaderSpy.Result.success([UUID().uuidString])
        let expectedResult = passedResult
        
        let exp = expectation(description: "Wait for async to be loaded")
        sut.load { result in
            switch (result, expectedResult) {
            case let (.success(loaded), .success(expected)):
                XCTAssertEqual(loaded, expected, "Expected to load \(expected) got \(loaded) instead")
            case let (.failure(loaded), .failure(expected)):
                XCTAssertEqual(loaded as NSError, expected as NSError, "Expected to load \(expected) got \(loaded) instead")
            default:
                XCTFail("Expected to load \(expectedResult) got \(result) instead")
            }
            exp.fulfill()
        }
        spy.complete(with: passedResult)
        wait(for: [exp], timeout: 1.0)
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
