//
//  Converter.swift
//  bricks
//
//  Created by Марина Чемезова on 07.05.2023.
//

import Foundation

/// Loads data using another **Query** and then converts the result to a **Target** type
public final class Converter<SourceQuery, Target>: Query where SourceQuery: Query
{
    public typealias TargetMapper = (SourceQuery.Result) -> Target
    
    private let query: SourceQuery
    private let map: TargetMapper
    
    /// Creates Converter with query and mapper
    /// - Parameters:
    ///   - query: An entity implementing **Query** protocol
    ///   - map: A closure to convert the loaded data from **Query.Result** to a **Target** type
    public init(query: SourceQuery, map: @escaping TargetMapper) {
        self.query = query
        self.map = map
    }
    
    /// Loads data using **SourceQuery** and then converts the result to a **Target** type using map closure passed in constructor upon creation
    public func load(_ completion: @escaping (Target) -> Void) {
        query.load { [weak self] result in
            guard let self else { return }
            completion(self.map(result))
        }
    }
}
