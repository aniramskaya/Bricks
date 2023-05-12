//
//  NotifyingQuery.swift
//  bricks
//
//  Created by Марина Чемезова on 12.05.2023.
//

import Foundation

/// ``FailableQuery`` which is able to notify sucscribers about successfull or failed load
///
/// Sometimes you may need to make some entity informed about query loading result. Use this decorator to make any failable query
public class NotifyingQuery<WrappedQuery: FailableQuery>: FailableQuery {
    public typealias Success = WrappedQuery.Success
    public typealias Failure = WrappedQuery.Failure
    
    private let wrappee: WrappedQuery
    private let onSuccess: ((Success) -> Void)?
    private let onFailure: ((Failure) -> Void)?
    
    public init(
        wrappee: WrappedQuery,
        onSuccess: ((Success) -> Void)? = nil,
        onFailure: ((Failure) -> Void)? = nil
    ) {
        self.wrappee = wrappee
        self.onSuccess = onSuccess
        self.onFailure = onFailure
    }
    
    public func load(completion: @escaping (Result<Success, Failure>) -> Void) {
        wrappee.load { [weak self] result in
            guard let self else { return }
            switch result {
            case let .success(success):
                self.onSuccess?(success)
            case let .failure(error):
                self.onFailure?(error)
            }
            completion(result)
        }
    }
}

extension FailableQuery {
    public func notify(onSuccess: ((Success) -> Void)?, onFailure: ((Failure) -> Void)?) -> NotifyingQuery<Self> {
        NotifyingQuery(wrappee: self, onSuccess: onSuccess, onFailure: onFailure)
    }
}
