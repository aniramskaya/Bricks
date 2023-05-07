//
//  bricksTests.swift
//  bricksTests
//
//  Created by Марина Чемезова on 07.05.2023.
//

import XCTest
@testable import bricks

protocol Mapper {
    associatedtype Source
    associatedtype Target
    
    func map(_: Source) -> Target
}

class Converter<SourceQuery, TargetMapper>: Query
    where SourceQuery: Query,
    TargetMapper: Mapper,
    TargetMapper.Source == SourceQuery.Result
{
    typealias Result = TargetMapper.Target
    let query: SourceQuery
    let mapper: TargetMapper
    
    init(query: SourceQuery, mapper: TargetMapper) {
        self.query = query
        self.mapper = mapper
    }
    
    func load(_ completion: @escaping (Result) -> Void) {
        query.load { [weak self] result in
            guard let self else { return }
            completion(self.mapper.map(result))
        }
    }
}

final class ConverterTests: XCTestCase {
    func test_converter_doesNotMessageUponCreation() throws {
        let (_, spy) = makeSUT()
        
        XCTAssertEqual(spy.messages, [])
    }
    
    func test_load_callsLoad() throws {
        let (sut, spy) = makeSUT()
        
        sut.load { _ in }
        
        XCTAssertEqual(spy.messages, [.load])
    }
    
    func test_load_convertsModel() throws {
        let (sut, spy) = makeSUT()
        let (source, target) = makeCompatibleSourceTarget()
        
        let exp = expectation(description: "wait for loading complete")
        var loadedResult: TargetModel?
        sut.load { result in
            loadedResult = result
            exp.fulfill()
        }
        spy.completeLoading(with: source)
        
        wait(for: [exp], timeout: 1.0)
        XCTAssertEqual(target, loadedResult)
        XCTAssertEqual(spy.messages, [.load, .map(source)])
    }

    // MARK: Private
    
    private func makeSUT() -> (Converter<QuerySpy, QuerySpy>, QuerySpy) {
        let spy = QuerySpy()
        let converter = Converter(query: spy, mapper: spy)
        
        return (converter, spy)
    }
    
    private func makeCompatibleSourceTarget() -> (SourceModel, TargetModel) {
        let uuid = UUID()
        return (SourceModel(value: uuid), TargetModel(value: uuid.uuidString))
    }
}

struct SourceModel: Equatable {
    let value: UUID
}

struct TargetModel: Equatable {
    let value: String
}

class QuerySpy: Query, Mapper {
    enum Message: Equatable {
        case load
        case map(SourceModel)
    }
    
    var messages: [Message] = []
    var completions: [(SourceModel) -> Void] = []
    
    func load(_ completion: @escaping (SourceModel) -> Void) {
        messages.append(.load)
        completions.append(completion)
        print(Date())
    }
    
    func completeLoading(with result: SourceModel, at index: Int = 0) {
        completions[index](result)
        print(Date())
    }
    
    func map(_ source: SourceModel) -> TargetModel {
        messages.append(.map(source))
        print(Date())
        return TargetModel(value: source.value.uuidString)
    }
}
