//
//  Converter.swift
//  bricks
//
//  Created by Марина Чемезова on 07.05.2023.
//

import Foundation

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
