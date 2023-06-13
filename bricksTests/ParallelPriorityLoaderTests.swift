//
//  ParallelPriorityLoaderTests.swift
//  WidgetsTests
//
//  Created by Марина Чемезова on 12.06.2023.
//

import Foundation
import XCTest
import bricks

/**
 Что тестируем
 
 ### Проверки логики загрузки
 
 [✅] Передаем 3 элемента с приоритетом ниже mandatory, равный ему и выше. Завершаем ошибкой загрузку того, что выше mandatory, проверяем что загрузка завершилась ошибкой.
 [✅] Передаем 3 элемента с приоритетом ниже mandatory, равный ему и выше. Завершаем ошибкой загрузку того, что равен mandatory, проверяем что загрузка завершилась ошибкой.
 [✅] Передаем 3 элемента с приоритетом ниже mandatory, равный ему и выше. Завершаем ошибкой загрузку того, что ниже mandatory, проверяем что загрузка не завершена.
 [✅] Передаем 3 элемента с приоритетом ниже mandatory, равный ему и выше. Завершаем загрузку того, что ниже mandatory. Проверяем что загрузка завершилась ошибкой таймаута.
 
 ### Проверки независимости запросов
 [✅] Запускаем 2 загрузки. Проверяем что они дают разные результаты при разных исходах загрузки элементов

 */

class ParallelPriorityLoaderTests: XCTestCase {
    enum Constants {
        static let mandtoryPriority: UInt = 100
    }
    
    func test_load_deliversRequiredLoadingErrorWhenOverMandatoryFails() {
        let (high, med, low) = makeItems()
        let (sut, spy) = makeSUT()

        expect(
            sut: sut,
            when: {
                spy.complete(with: .success([high, med, low].erased))
                high.complete(with: .failure(NSError.any()))
            },
            toCompleteWith: .failure(ParallelizedLoaderError.requredLoadingFailed)
        )
    }
    
    func test_load_deliversRequiredLoadingErrorWhenMandatoryFails() {
        let (high, med, low) = makeItems()
        let (sut, spy) = makeSUT()

        expect(
            sut: sut,
            when: {
                spy.complete(with: .success([high, med, low].erased))
                med.complete(with: .failure(NSError.any()))
            },
            toCompleteWith: .failure(ParallelizedLoaderError.requredLoadingFailed)
        )
    }

    func test_load_deliversTimeoutErrorWhenAtLeaseOneMandatoryTimedOut() {
        let (high, med, low) = makeItems()
        let (sut, spy) = makeSUT()

        expect(
            sut: sut,
            when: {
                spy.complete(with: .success([high, med, low].erased))
                low.complete(with: .success(UUID()))
                high.complete(with: .success(UUID()))
            },
            toCompleteWith: .failure(ParallelizedLoaderError.timeoutExpired)
        )
    }

    func test_load_deliversSuccessWhenMandatorySucceeded() {
        let (high, med, low) = makeItems()
        let (sut, spy) = makeSUT()

        let highSuccess = UUID()
        let medSuccess = UUID()
        expect(
            sut: sut,
            when: {
                spy.complete(with: .success([high, med, low].erased))
                high.complete(with: .success(highSuccess))
                med.complete(with: .success(medSuccess))
            },
            toCompleteWith: .success([highSuccess, medSuccess, nil])
        )
    }

    func test_loadTwice_deliversDistinctResults() {
        let (sut, spy) = makeSUT()

        let (high1, med1, low1) = makeItems()
        let (high2, med2, low2) = makeItems()
        
        let exp = expectation(description: "Wait for loading to complete")
        exp.expectedFulfillmentCount = 2
        
        var load1Result: Result<[UUID?], ParallelizedLoaderError>?
        sut.load { result in
            load1Result = result
            exp.fulfill()
        }
        var load2Result: Result<[UUID?], ParallelizedLoaderError>?
        sut.load { result in
            load2Result = result
            exp.fulfill()
        }
        spy.complete(with: .success([high1, med1, low1].erased), at: 0)
        spy.complete(with: .success([high2, med2, low2].erased), at: 1)

        high1.complete(with: .failure(NSError.any()))
        let high2Success = UUID()
        let med2Success = UUID()
        high2.complete(with: .success(high2Success))
        med2.complete(with: .success(med2Success))
        
        wait(for: [exp], timeout: 1.0)

        assertEqual(result: load1Result, expected: .failure(ParallelizedLoaderError.requredLoadingFailed))
        assertEqual(result: load2Result, expected: .success([high2Success, med2Success, nil]))
    }
    
    func test_load_doesNotCallCompleteWhenSUTDeallocatedWhileWrappeeExecuting() {
        let spy = ItemsLoaderSpy()
        var sut: ParallelPriorityLoader<UUID, ItemsLoaderSpy>? = ParallelPriorityLoader<UUID, ItemsLoaderSpy>(
            wrappee: spy,
            mandatoryPriority: .custom(Constants.mandtoryPriority),
            timeout: { 0.5 }
        )
        
        let (high, med, low) = makeItems()
        
        var completionCallCount = 0
        sut!.load { result in
            completionCallCount += 1
        }
        sut = nil
        spy.complete(with: .success([high, med, low].erased))
        
        XCTAssertEqual(completionCallCount, 0)
    }

    func test_load_doesNotCallCompleteWhenSUTDeallocatedWhileItemsLoading() {
        let spy = ItemsLoaderSpy()
        var sut: ParallelPriorityLoader<UUID, ItemsLoaderSpy>? = ParallelPriorityLoader<UUID, ItemsLoaderSpy>(
            wrappee: spy,
            mandatoryPriority: .custom(Constants.mandtoryPriority),
            timeout: { 0.5 }
        )
        
        let (high, med, low) = makeItems()
        
        var completionCallCount = 0
        sut!.load { result in
            completionCallCount += 1
        }
        spy.complete(with: .success([high, med, low].erased))
        
        sut = nil
        
        high.complete(with: .success(UUID()))
        
        XCTAssertEqual(completionCallCount, 0)
    }

    private func makeSUT() -> (ParallelPriorityLoader<UUID, ItemsLoaderSpy>, ItemsLoaderSpy) {
        let spy = ItemsLoaderSpy()
        let sut = ParallelPriorityLoader<UUID, ItemsLoaderSpy>(
            wrappee: spy,
            mandatoryPriority: .custom(Constants.mandtoryPriority),
            timeout: { 0.5 }
        )
        
        return (sut, spy)
    }

    private func makeItems() -> (ParallelPriorityItemSpy, ParallelPriorityItemSpy, ParallelPriorityItemSpy) {
        return (
            ParallelPriorityItemSpy(priority: .custom(Constants.mandtoryPriority + 1)),
            ParallelPriorityItemSpy(priority: .custom(Constants.mandtoryPriority)),
            ParallelPriorityItemSpy(priority: .custom(Constants.mandtoryPriority - 1))
        )
    }
    
    private func expect(sut: ParallelPriorityLoader<UUID, ItemsLoaderSpy>, when action: () -> Void, toCompleteWith expectedResult: Result<[UUID?], ParallelizedLoaderError>) {
        let exp = expectation(description: "Wait for loading to complete")
        sut.load { [weak self] result in
            self?.assertEqual(result: result, expected: expectedResult)
            exp.fulfill()
        }
        action()

        wait(for: [exp], timeout: 1.0)
    }

    private func assertEqual(result: Result<[UUID?], ParallelizedLoaderError>?, expected: Result<[UUID?], ParallelizedLoaderError>) {
        guard let result else {
            XCTFail("Expected non-nil result")
            return
        }
        switch (result, expected) {
        case let (.failure(error), .failure(expectedError)):
            XCTAssertEqual(error as NSError, expectedError as NSError)
        case let (.success(value), .success(expectedValue)):
            XCTAssertEqual(value, expectedValue)
        default:
            XCTFail("Expected \(expected) got \(result) instead")
        }
    }
    
}

private extension Array where Element == ParallelPriorityItemSpy {
    var erased: [AnyPriorityLoadingItem<UUID, Error>] { self.map { $0.eraseToAnyPriorityLoadingItem() } }
}

private class ItemsLoaderSpy: FailableQuery {
    typealias Success = [AnyPriorityLoadingItem<UUID, Error>]
    typealias Failure = Error
    
    var completions: [(Result<Success, Failure>) -> Void] = []
    func load(completion: @escaping (Result<Success, Failure>) -> Void) {
        completions.append(completion)
    }
    
    func complete(with result: Result<Success, Failure>, at index: Int = 0) {
        completions[index](result)
    }
}

private class ParallelPriorityItemSpy: PriorityLoadingItem {
    typealias Success = UUID
    typealias Failure = Swift.Error
    
    let priority: ParallelPriority
    
    init(priority: ParallelPriority) {
        self.priority = priority
    }

    enum Message {
        case load
    }
    var messages: [Message] = []
    var completions: [(Result<UUID, Error>) -> Void] = []
    
    func load(_ completion: @escaping (Result<UUID, Error>) -> Void) {
        messages.append(.load)
        completions.append(completion)
    }
    
    func complete(with result: Result<UUID, Error>, at index: Int = 0) {
        completions[index](result)
    }
}
