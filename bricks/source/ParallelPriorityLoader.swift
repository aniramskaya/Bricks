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
}

public class ParallelPriorityLoader<Success> {
    public typealias Failure = ParallelizedLoaderError
    public typealias Element = AnyPriorityLoadingItem<Success, Swift.Error>
    
    public init () {}
    
    public func load(
        items: [Element],
        mandatoryPriority: ParallelPriority,
        timeout: TimeInterval,
        completion: @escaping (Result<[Success?], Failure>) -> Void
    ) {
        let id = UUID()
        let loader = InternalPriorityLoader(items: items, mandatoryPriority: mandatoryPriority, timeout: timeout) { [weak self] result in
            completion(result)
            self?.removeLoader(id: id)
        }
        addLoader(loader, id: id)
        loader.load()
    }
    
    // MARK: - Private
    
    private var executingLoaders: [UUID: InternalPriorityLoader<Success>] = [:]
    private var executingLoadersLock = NSRecursiveLock()
    
    private func addLoader(_ loader: InternalPriorityLoader<Success>, id: UUID) {
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
    typealias Element = AnyPriorityLoadingItem<Success, Swift.Error>
    
    private let items: [Element]
    private var results: [Success?]
    private let mandatoryPriority: ParallelPriority
    private let completion: (Result<[Success?], Failure>) -> Void
    private let timer: Timer

    init(
        items: [Element],
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
