//
//  Converter.swift
//  bricks
//
//  Created by Марина Чемезова on 07.05.2023.
//

import Foundation

public class Converter<SourceQuery, Target>: Query where SourceQuery: Query
{
    public typealias TargetMapper = (SourceQuery.Result) -> Target
    
    private let query: SourceQuery
    private let map: TargetMapper
    
    public init(query: SourceQuery, map: @escaping TargetMapper) {
        self.query = query
        self.map = map
    }
    
    public func load(_ completion: @escaping (Target) -> Void) {
        query.load { [weak self] result in
            guard let self else { return }
            completion(self.map(result))
        }
    }
}
