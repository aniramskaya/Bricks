//
//  Converter.swift
//  bricks
//
//  Created by Марина Чемезова on 07.05.2023.
//

import Foundation

public protocol Mapper {
    associatedtype Source
    associatedtype Target
    
    func map(_: Source) -> Target
}

public class Converter<SourceQuery, TargetMapper>: Query
    where SourceQuery: Query,
    TargetMapper: Mapper,
    TargetMapper.Source == SourceQuery.Result
{
    public typealias Result = TargetMapper.Target
    private let query: SourceQuery
    private let mapper: TargetMapper
    
    public init(query: SourceQuery, mapper: TargetMapper) {
        self.query = query
        self.mapper = mapper
    }
    
    public func load(_ completion: @escaping (Result) -> Void) {
        query.load { [weak self] result in
            guard let self else { return }
            completion(self.mapper.map(result))
        }
    }
}
