//
//  PriorityLoadingItem.swift
//  Widgets
//
//  Created by Марина Чемезова on 12.06.2023.
//

import Foundation

public protocol PriorityLoadingItem {
    associatedtype Success
    associatedtype Failure: Swift.Error
    var priority: ParallelPriority { get }
    
    func load(_ completion: @escaping (Result<Success, Failure>) -> Void)
}

// MARK: - Type eraser

public struct AnyPriorityLoadingItem<Success, Failure: Error>: PriorityLoadingItem {
    private class AnyPriorityLoadingItemBoxBase<Item: PriorityLoadingItem>: AnyPriorityLoadingItemBox<Item.Success, Item.Failure> {
        let base: Item
        init(base: Item) {
            self.base = base
        }
        override var priority: ParallelPriority { base.priority }
        
        override func load(_ completion: @escaping (Result<Item.Success, Item.Failure>) -> Void) {
            base.load(completion)
        }
    }

    private class AnyPriorityLoadingItemBox<Success, Failure: Error> {
        var priority: ParallelPriority { fatalError() }
        
        func load(_ completion: @escaping (Result<Success, Failure>) -> Void) {
            fatalError()
        }
    }
    
    private let wrappee: AnyPriorityLoadingItemBox<Success, Failure>
    
    init<T>(_ wrappee: T) where T: PriorityLoadingItem, T.Success == Success, T.Failure == Failure {
        self.wrappee = AnyPriorityLoadingItemBoxBase(base: wrappee)
    }
    
    public var priority: ParallelPriority { wrappee.priority }
    
    public func load(_ completion: @escaping (Result<Success, Failure>) -> Void) {
        wrappee.load(completion)
    }
}



public extension PriorityLoadingItem {
    func eraseToAnyPriorityLoadingItem() -> AnyPriorityLoadingItem<Success, Failure> {
        return AnyPriorityLoadingItem(self)
    }
}
