//
//  DemultiplyingQuery.swift
//  bricks
//
//  Created by Марина Чемезова on 27.05.2023.
//

import Foundation

/// ``Query`` which guarantees that only single loading operation is performed over WrappedQuery at any point in time.
///
/// ``DemultiplyingQuery`` calls ``WrappedQuery.load`` only if it is not running at the moment. Otherwise it stores completion closure and calls it when loading has finished. This class is thread safe.
public final class DemultiplyingQuery<WrappedQuery: Query>: Query
{
    public typealias Result = WrappedQuery.Result
    
    private var query: WrappedQuery
    private var completions: [(WrappedQuery.Result) -> Void] = []
    private var completionsLock = NSRecursiveLock()
    
    
    /// Designated initializer.
    ///
    /// - Parameters:
    ///   - query: Query to wrap
    public init(query: WrappedQuery) {
        self.query = query
    }
    
    /// Loads data from `query`
    ///
    /// This method calls query if there is no running query at the moment. Otherwise it stores completion block which is called when loading has completed.
    ///
    /// - Parameters:
    ///   - completion: A closure which is called when the loading process has complete.
    public func load(completion: @escaping (Result) -> Void) {
        if add(completion) {
            query.load { [weak self] result in
                self?.completeAll(with: result)
            }
        }
    }
    
    // MARK: - Private

    private func add(_ completion: @escaping (Result) -> Void) -> Bool {
        completionsLock.lock()
        let isFirstCompletion = completions.isEmpty
        completions.append(completion)
        completionsLock.unlock()
        return isFirstCompletion
    }
    
    private func completeAll(with result: Result) {
        completionsLock.lock()
        let captured = completions
        completions = []
        completionsLock.unlock()
        for item in captured {
            item(result)
        }
    }
}
