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
    }
}

final class ConverterTests: XCTestCase {
    func test_converter_doesNotMessageUponCreation() {
        let spy = QuerySpy()
        let _ = Converter(query: spy, mapper: spy)
        
        XCTAssertEqual(spy.messages, [])
    }
}

struct SourceModel: Equatable {
    let value: UUID
}

struct TargetModel {
    let value: String
}

class QuerySpy: Query, Mapper {
    enum Message: Equatable {
        case load
        case map(SourceModel)
    }
    
    var messages: [Message] = []
    
    func load(_ completion: @escaping (SourceModel) -> Void) {
        messages.append(.load)
    }
    
    func map(_ source: SourceModel) -> TargetModel {
        messages.append(.map(source))
        return TargetModel(value: "")
    }
}
