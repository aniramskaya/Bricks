//
//  Command.swift
//  bricks
//
//  Created by Марина Чемезова on 31.05.2023.
//

import Foundation

///  Command executes some action and returns resulting entity
///
///  Ideally, command should only execute some action without returning any value. Since we are working in the RESTful world, we have to adapt to its pecularities and often return modified entity in response. Therefore, `Command` uses a ``FailableQuery`` under the hood to be able to return an entity modified by command execution.
///
///  Don't be confused with the fact that `Command` expects a single parameter. Since it has no restrictions on parameter type, you may use any type which aggregates all the parameters you need.
///
///  Since command uses query to load resulting entity and there is no chance to pass parameters to query, it needs to create a new instance of query for every call to ``execute(_:completion:)`` method. To provide this functionality `Command` requires to have a query builder passed into the initializer.
public class Command<Param, CommandQuery> where CommandQuery: FailableQuery {
    private let buildQuery: (Param) -> CommandQuery

    /// Creates Query command with associated query builder.
    ///
    /// Query builder is called every time you call execute method, passing parameters from ``execute(_:completion:)`` to query biulder without any modifications. Resulting query is used only for a single call of ``execute(_:completion:)`` and is discarded once command has finished.
    /// - Parameters:
    ///   - queryBuilder: A closure which receives command parameters and should return a Query which is able to pass those parameters to backing service (Web, DB, etc). It should somehow incorporate parameter into the query. For example, it may pass the param into `CommandQuery` initializer.
    public init(queryBuilder: @escaping (Param) -> CommandQuery) {
        self.buildQuery = queryBuilder
    }
    
    /// Executes command using passed parameters and calls completion when finished passing the entity modified by the command.
    /// - Parameters:
    ///   - param: Generic command parameter
    ///   - completion: Completion to be called when command execution has finished
    public func execute(_ param: Param, completion: @escaping (CommandQuery.Result) -> Void) {
        let query = buildQuery(param)
        query.load(completion: completion)
    }
}
