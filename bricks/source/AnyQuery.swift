//
//  AnyQuery.swift
//  bricks
//
//  Created by Марина Чемезова on 21.05.2023.
//

import Foundation

// Type erasing wrapper for FailableQuery
public struct AnyQuery<Result>: Query {
    private class _AnyQueryBox<Result>: Query {
        func load(completion: @escaping (Result) -> Void) {
            fatalError("This method is abstract")
        }
    }
    
    private class _QueryBox<Base: Query>: _AnyQueryBox<Base.Result> {
       private let _base: Base
       init(_ base: Base) {
          _base = base
       }
        
        override func load(completion: @escaping (Result) -> Void) {
            return _base.load(completion: completion)
       }
    }
    
    private let _box: _AnyQueryBox<Result>
    
    public init<Q>(_ wrappee: Q) where Q: Query, Q.Result == Result {
        _box = _QueryBox(wrappee)
    }
    
    public func load(completion: @escaping (Result) -> Void) {
        _box.load(completion: completion)
    }
}

public extension FailableQuery {
    func erased() -> AnyQuery<Self.Result> {
        AnyQuery(self)
    }
}
