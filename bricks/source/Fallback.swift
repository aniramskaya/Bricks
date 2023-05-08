//
//  Fallback.swift
//  bricks
//
//  Created by Марина Чемезова on 07.05.2023.
//

import Foundation

/// Fallback wraps two queries.
///
/// If the primary query completes with success ``Fallback`` returns success. Otherwise it calls fallback query and returns its result in completion when completed.
public final class Fallback<Primary: FailableQuery, Secondary: FailableQuery>: FailableQuery
    where Primary.Success == Secondary.Success
{
    public typealias Success = Secondary.Success
    public typealias Failure = Secondary.Failure
    
    private let primary: Primary
    private let fallback: Secondary
    
    public init(primary: Primary, fallback: Secondary) {
        self.primary = primary
        self.fallback = fallback
    }
    
    public func load(completion: @escaping (_ result: Result<Success, Failure>) -> Void) {
        primary.load {[weak self] result in
            guard let self else { return }
            switch result {
            case .failure:
                self.loadFallback(completion)
            case let .success(value):
                completion(.success(value))
            }
        }
    }
    
    private func loadFallback(_ completion: @escaping (_ result: Result<Success, Failure>) -> Void) {
        fallback.load {[weak self] result in
            guard self != nil else { return }
            completion(result)
        }
    }
    
}
