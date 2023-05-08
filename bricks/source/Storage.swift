//
//  Storage.swift
//  bricks
//
//  Created by Марина Чемезова on 08.05.2023.
//

import Foundation

/// General purpose storage.
///
/// Conform this protocol in your own storage classes to make them seamlessly integrated with ``bricks`` tools.
///
/// As many posible types of storage including a file or a database have asynchronous behavior, this protocol is inherently asynchronous.
public protocol Storage {
    /// Type of data to store
    associatedtype Stored
    
    /// The date of the last successful ``save(completion:)`` operation
    var timestamp: Date? { get }
    
    /// Retrieves stored value
    ///
    /// Different implementations may have different rules how to deal with loading errors. The **Swift.Result** which is used in the closure parameter only express the fact that loading may fail.
    ///
    /// - Parameters:
    ///   - completion: A closure to be called when loading has completed.
    ///
    func load(completion: (Result<Stored, Error>) -> Void)
    
    /// Saves value
    ///
    /// - Parameters:
    ///   - completion: A closure to be called when the save operation has finished. Any saving error should be passed inside the completion closure.
    func save(completion: (Error?) -> Void)
    
    /// Removes stored value, if any
    ///
    /// Clean should also reset the ``timestamp`` value to `nil`.
    ///
    /// - Parameters:
    ///   - completion: A closure to be called when the clean operation has finished. Any error should be passed inside the completion closure.
    func clear(completion: (Error?) -> Void)
}

///  Synchronous storage. Stores a value synchronously on the thread it was called from.
///
///  This type of storage is usually in-memory storage because other types are inherently asynchronous
public protocol SynchronousStorage {
    /// Type of data to store
    associatedtype Stored
    
    /// The date of the last save operation
    var timestamp: Date? { get }
    
    /// Retrieves stored value
    func load() -> Stored?
    
    /// Saves value.
    ///
    /// It is up to concrete implementation to decide wether `save` overrides the previously stored value or not.
    func save(_: Stored)
    
    /// Removes stored value, if any
    func clear()
}
