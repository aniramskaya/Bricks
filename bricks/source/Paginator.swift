//
//  Paginator.swift
//  bricks
//
//  Created by Марина Чемезова on 05.06.2023.
//

import Foundation

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

 
 Paginator needs a query to load data
 It might be created each time when load or loadMore is called
 
 Paginator scenarios
 
 Given: no data has been loaded yet
 When: load is called
 ✅ Then: loads first page data returning items and hasMore flag on success or error on failure

 Given: data has been loaded
 When: load is called
 ✅ Then: returns items from memory
 
 Given: data has been loaded
 When: loadMore is called
 ✅ Then: loads next page data returning items and hasMore flag on success or error on failure
 
 Given: data has been loaded
 When: reset is called
 ✅ Then: deletes loaded data
 
 [✅] Test that paginator does not call completion when destroyed while loading
 [✅] Test that query created with builder does not disappear on leaving load method
 [✅] Test that paginator demultiplies multiple calls
 
 */

public protocol ListFailableQuery: FailableQuery where Success == Array<Element> {
    associatedtype Element: Hashable
}

public final class Paginator<PageQuery: ListFailableQuery> {
    public typealias Result = Swift.Result<(PageQuery.Success, Bool), PageQuery.Failure>
    
    private let queryBuilder: (Int) -> PageQuery
    private let firstPageNumber: Int
    
    public init(queryBuilder: @escaping (Int) -> PageQuery, firstPageNumber: Int = 0) {
        self.queryBuilder = queryBuilder
        self.firstPageNumber = firstPageNumber
        self.pageNumber = firstPageNumber
    }
    
    public func load(_ completion: @escaping (Paginator.Result) -> Void) {
        if let loadedData {
            completion(.success(loadedData))
            return
        }
        loadMore(completion)
    }
    
    public func loadMore(_ completion: @escaping (Paginator.Result) -> Void) {
        completionsLock.lock()
        completions.append(completion)
        if inProgress == nil {
            let query = queryBuilder(pageNumber)
            inProgress = query
            query.load { [weak self] result in
                guard let self else { return }
                self.completeAll(with: result)
            }
        }
        completionsLock.unlock()
    }
    
    public func reset() {
        completionsLock.lock()
        completions = []
        inProgress = nil
        loadedData = nil
        pageNumber = firstPageNumber
        completionsLock.unlock()
    }
    
    // MARK: - Private

    private var inProgress: PageQuery?
    private var completions: [(Paginator.Result) -> Void] = []
    private var completionsLock = NSRecursiveLock()
    private var loadedData: (PageQuery.Success, Bool)?
    private var pageNumber: Int

    private func completeAll(with loadedResult: PageQuery.Result) {
        completionsLock.lock()
        let captured = completions
        completions = []
        inProgress = nil
        let result = loadedResult.map { ( (loadedData?.0 ?? []) + $0, !$0.isEmpty) }
        if let newData = try? result.get() {
            loadedData = newData
            pageNumber += 1
        }
        completionsLock.unlock()
        for item in captured {
            item(result)
        }
    }
}
