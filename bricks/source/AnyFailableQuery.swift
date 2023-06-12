//
//  AnyFailableQuery.swift
//  bricks
//
//  Created by Марина Чемезова on 21.05.2023.
//

import Foundation

// Type erasing wrapper for FailableQuery
_public struct AnyFailableQuery<Success, Failure: Error>: FailableQuery {
    private class _AnyFailableQueryBox<Success, Failure: Error>: FailableQuery {
        func load(completion: @escaping (Swift.Result<Success, Failure>) -> Void) {
            fatalError("This method is abstract")
        }
    }
    
    private class _FailableQueryBox<Base: FailableQuery>: _AnyFailableQueryBox<Base.Success, Base.Failure> {
       private let _base: Base
       init(_ base: Base) {
          _base = base
       }
        
        override func load(completion: @escaping (Swift.Result<Success, Failure>) -> Void) {
            return _base.load(completion: completion)
       }
    }
    
    private let _box: _AnyFailableQueryBox<Success, Failure>
    
    public init<Q>(_ wrappee: Q) where Q: FailableQuery, Q.Success == Success, Q.Failure == Failure {
        _box = _FailableQueryBox(wrappee)
    }
    
    public func load(completion: @escaping (Swift.Result<Success, Failure>) -> Void) {
        _box.load(completion: completion)
    }
}

public extension FailableQuery {
    func erased() -> AnyFailableQuery<Self.Success, Self.Failure> {
        AnyFailableQuery(self)
    }
}
