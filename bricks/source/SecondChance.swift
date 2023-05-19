//
//  Fallback.swift
//  bricks
//
//  Created by Марина Чемезова on 07.05.2023.
//

import Foundation

/// SecondChance combines two ``FailableQuery`` instances calling the second only in the case when the first has failed.
///
/// If the primary query completes with success ``Fallback`` returns success. Otherwise it keeps primary query error and calls secondary query. If secondary returns success ``SecondChance`` returns sucess. If secondary fails ``SecondChance`` returns an error received from primary.
///
/// > Impotant: Notice that Fallback only requires equivalence of **Success** types for both queries, and they may have different **Failure** types. As Fallback never returns **Failure** from **secondary** (as discussed in ``load(completion:)``) its own **Failure** type is always the same as **Failure** of **primary**.
///
/// > Warning: Don't be confused with ``Fallback`` and ``SecondChance``. They work in the same approach and the only difference is that when both queries failed ``Fallback`` returns second query error but ``SecondChance`` returns first query error.
public final class SecondChance<Primary: FailableQuery, Secondary: FailableQuery>: FailableQuery
    where Primary.Success == Secondary.Success
{
    public typealias Success = Primary.Success
    public typealias Failure = Primary.Failure
    
    private let primary: Primary
    private let secondary: Secondary
    
    public init(primary: Primary, secondary: Secondary) {
        self.primary = primary
        self.secondary = secondary
    }
    
    
    /// Calls **primary** query and if it fails calls **fallback** query.
    ///
    /// - If the primary query has succeeded its result is passed into completion.
    /// - If the primary has failed, **load** calls secondary query and when it completes calls completion with either success of the second query or failure of the primary
    ///
    ///  This logic means that the **error** of **secondary failure** is always discarded and never passed to the completion closure.
    ///
    /// - Parameters:
    ///   - completion: A closure which is called when the loading process has complete.
    public func load(completion: @escaping (_ result: Result<Success, Failure>) -> Void) {
        primary.load {[weak self] result in
            guard let self else { return }
            switch result {
            case let .failure(error):
                self.loadSecondChance(completion, error)
            case let .success(value):
                completion(.success(value))
            }
        }
    }
    
    private func loadSecondChance(
        _ completion: @escaping (_ result: Result<Success, Failure>) -> Void,
        _ error: Failure
    ) {
        secondary.load {[weak self] result in
            guard self != nil else { return }
            switch result {
            case .failure:
                completion(.failure(error))
            case let .success(value):
                completion(.success(value))
            }
        }
    }
}

public extension FailableQuery {
    /// Creates ``SecondChance`` using **self** as the primary query
    ///
    /// - Parameters:
    ///   - secondary: Secondary fallback query
    func secondChance<Secondary: FailableQuery>(_ secondary: Secondary) -> SecondChance<Self, Secondary> where Secondary.Success == Success {
        SecondChance(primary: self, secondary: secondary)
    }
}
