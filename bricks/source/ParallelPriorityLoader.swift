//
//  MandatorySynchronizer.swift
//  Widgets
//
//  Created by Марина Чемезова on 08.06.2023.
//

import Foundation

public enum ParallelizedLoaderError: Error {
    case requredLoadingFailed
    case timeoutExpired
    case loadingFailed(Error)
}

public class ParallelPriorityLoader<ItemType, WrappedQuery>: FailableQuery where WrappedQuery: FailableQuery, WrappedQuery.Success == [AnyPriorityLoadingItem<ItemType, Swift.Error>] {
    public typealias Success = [ItemType?]
    public typealias Failure = ParallelizedLoaderError
    
    private let wrappee: WrappedQuery
    private let mandatoryPriority: ParallelPriority
    private let timeout: () -> TimeInterval
    
    public init(wrappee: WrappedQuery, mandatoryPriority: ParallelPriority, timeout: @escaping () -> TimeInterval) {
        self.wrappee = wrappee
        self.mandatoryPriority = mandatoryPriority
        self.timeout = timeout
    }
    
    public func load(
        completion: @escaping (Result<[ItemType?], Failure>) -> Void
    ) {
        wrappee.load { [weak self] result in
            guard let self else { return }
            switch result {
            case let .success(items):
                self.loadItems(items, completion: completion)
            case let .failure(error):
                completion(.failure(.loadingFailed(error)))
            }
        }
    }
    
    // MARK: - Private
    
    private func loadItems(
        _ items: WrappedQuery.Success,
        completion: @escaping (Result<[ItemType?], Failure>) -> Void
    ) {
        let id = UUID()
        let loader = InternalPriorityLoader(items: items, mandatoryPriority: mandatoryPriority, timeout: timeout()) { [weak self] result in
            completion(result)
            self?.removeLoader(id: id)
        }
        addLoader(loader, id: id)
        loader.load()
    }

    private var executingLoaders: [UUID: InternalPriorityLoader<ItemType>] = [:]
    private var executingLoadersLock = NSRecursiveLock()
    
    private func addLoader(_ loader: InternalPriorityLoader<ItemType>, id: UUID) {
        executingLoadersLock.lock()
        executingLoaders[id] = loader
        executingLoadersLock.unlock()
    }
    
    private func removeLoader(id: UUID) {
        executingLoadersLock.lock()
        executingLoaders[id] = nil
        executingLoadersLock.unlock()
    }
}

private class InternalPriorityLoader<Success> {
    typealias Failure = ParallelizedLoaderError
    
    private let items: [AnyPriorityLoadingItem<Success, Swift.Error>]
    private var results: [Success?]
    private let mandatoryPriority: ParallelPriority
    private let completion: (Result<[Success?], Failure>) -> Void
    private let timer: Timer

    init(
        items: [AnyPriorityLoadingItem<Success, Swift.Error>],
        mandatoryPriority: ParallelPriority,
        timeout: TimeInterval,
        completion: @escaping (Result<[Success?], Failure>) -> Void
    ) {
        self.items = items
        self.results = [Success?](repeating: nil, count: items.count)
        self.mandatoryPriority = mandatoryPriority
        self.timer = Timer(timeInterval: timeout, repeats: false, block: { _ in
            completion(.failure(ParallelizedLoaderError.timeoutExpired))
        })
        self.completion = completion
    }

    deinit {
        timer.invalidate()
    }

    func load() {
        RunLoop.main.add(timer, forMode: .default)
        for (index, item) in items.enumerated() {
            item.load { [weak self] result in
                guard let self else { return }
                switch result {
                case .failure:
                    if item.priority >= self.mandatoryPriority {
                        self.completion(.failure(ParallelizedLoaderError.requredLoadingFailed))
                        return
                    }
                case let .success(value):
                    self.results[index] = value
                }
                self.completeIfNeeded()
            }
        }
    }
    
    // MARK: - Private
    
    private func completeIfNeeded() {
        var areAllMandatoryFinished = true
        for (index, item) in items.enumerated() {
            if item.priority >= mandatoryPriority {
                if results[index] == nil {
                    areAllMandatoryFinished = false
                }
            }
        }
        if areAllMandatoryFinished {
            completion(.success(results))
        }
    }
}

public extension FailableQuery {
    func loadMandatory<ItemType>(
        mandatoryPriority: ParallelPriority,
        timeout: @escaping () -> TimeInterval
    ) -> ParallelPriorityLoader<ItemType, Self> where Success == [AnyPriorityLoadingItem<ItemType, Swift.Error>] {
        ParallelPriorityLoader(wrappee: self, mandatoryPriority: mandatoryPriority, timeout: timeout)
    }
}
