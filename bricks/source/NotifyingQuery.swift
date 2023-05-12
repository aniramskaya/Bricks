//
//  NotifyingQuery.swift
//  bricks
//
//  Created by Марина Чемезова on 12.05.2023.
//

import Foundation

/// ``FailableQuery`` which is able to notify subscribers about successfull or failed load
///
/// Sometimes you may need to make some entity informed about query loading result. Use this decorator to make any failable query to notify about query loading result.
public class NotifyingQuery<WrappedQuery: FailableQuery>: FailableQuery {
    public typealias Success = WrappedQuery.Success
    public typealias Failure = WrappedQuery.Failure
    
    private let wrappee: WrappedQuery
    private let onSuccess: ((Success) -> Void)?
    private let onFailure: ((Failure) -> Void)?
    
    /// Designated initializer
    ///
    /// - Parameters:
    ///   - wrappee: ``FailableQuery`` to be decorated
    ///   - onSuccess: Closure to be called when loading has completed with success. Success value is passed into it without any modifications.
    ///   - onFailure: Closure to be called when loading hasCompleted with failure. Failure value is passed into it without any modifications.
    public init(
        wrappee: WrappedQuery,
        onSuccess: ((Success) -> Void)? = nil,
        onFailure: ((Failure) -> Void)? = nil
    ) {
        self.wrappee = wrappee
        self.onSuccess = onSuccess
        self.onFailure = onFailure
    }
    
    /// Loads data using wrapped query calling `onSuccess` and `onFailure` closures when finished.
    ///
    /// This method calls ``load(completion:)`` at wrapped query and calls `onResult` on success and `onFailure` on failure accordingly. The result is passed into completion closure without any modifications.
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
    /// Helper to create ``NotifyingQuery`` using chaining passing `self` as wrappee to newly created wrapper.
    ///
    /// - Parameters:
    ///   - onSuccess: Closure to be called when loading has completed with success
    ///   - onFailure: Closure to be called when loading hasCompleted with failure
    public func notify(onSuccess: ((Success) -> Void)?, onFailure: ((Failure) -> Void)?) -> NotifyingQuery<Self> {
        NotifyingQuery(wrappee: self, onSuccess: onSuccess, onFailure: onFailure)
    }
}
