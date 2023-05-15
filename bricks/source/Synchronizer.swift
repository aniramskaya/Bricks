//
//  Synchronizer.swift
//  bricks
//
//  Created by Марина Чемезова on 15.05.2023.
//

import Foundation

/// Executes two different ``Query`` in parallel and completes when both queries have completed
public class Synchronizer<Query1: Query, Query2: Query>: Query {
    public typealias Result = (Query1.Result, Query2.Result)
    
    private let query1: Query1
    private let query2: Query2
    private let queue: DispatchQueue
    
    public init(_ query1: Query1, _ query2: Query2) {
        queue = DispatchQueue(label: "Query Synchronizer Queue")
        self.query1 = query1
        self.query2 = query2
    }
    
    /// Starts queries injected into initializer and calls completion when both of them completed
    ///
    /// - Parameters:
    ///   - completion: Completion closure which accepts tuple with results from query1 and query2 accordingly
    public func load(completion: @escaping ((Query1.Result, Query2.Result)) -> Void) {
        let dispatchGroup = DispatchGroup()
        var result1: Query1.Result?
        var result2: Query2.Result?

        dispatchGroup.enter()
        dispatchGroup.enter()
        
        dispatchGroup.notify(queue: queue, work: DispatchWorkItem(block: { [weak self] in
            guard self != nil else { return }
            completion((result1!, result2!))
        }))
        
        query1.load {
            result in result1 = result
            dispatchGroup.leave()
        }
        query2.load {
            result in result2 = result
            dispatchGroup.leave()
        }
    }
}
