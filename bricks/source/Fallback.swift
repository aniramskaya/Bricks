//
//  Fallback.swift
//  bricks
//
//  Created by Марина Чемезова on 07.05.2023.
//

import Foundation

/// Fallback combines two ``FailableQuery`` instances calling the second only in the case when the first has failed.
///
/// If the primary query completes with success ``Fallback`` returns success. Otherwise it calls secondary query and returns its result in completion when completed.
/// > Impotant: Notice that Fallback only requires equivalence of **Success** types for both queries, and they may have different **Failure** types. As Fallback never returns **Failure** from **primary** (as discussed in ``load(completion:)``) its own **Failure** type is always the same as **Failure** of **secondary**.
public final class Fallback<Primary: FailableQuery, Secondary: FailableQuery>: FailableQuery
    where Primary.Success == Secondary.Success
{
    public typealias Success = Secondary.Success
    public typealias Failure = Secondary.Failure
    
    private let primary: Primary
    private let secondary: Secondary
    
    public init(primary: Primary, secondary: Secondary) {
        self.primary = primary
        self.secondary = secondary
    }
    
    
    /// Calls **primary** query and if it fails calls **fallback** query.
    ///
    /// - If the primary query has succeeded its result is passed into completion.
    /// - If the primary has failed, **load** calls fallback query and when it completes calls completion with its result
    ///
    ///  This logic means that the **error** of **primary failure** is always discarded and never passed to the completion closure.
    ///
    /// - Parameters:
    ///   - completion: A closure which is called when the loading process has complete.
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
        secondary.load {[weak self] result in
            guard self != nil else { return }
            completion(result)
        }
    }
}
