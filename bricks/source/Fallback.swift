//
//  Fallback.swift
//  bricks
//
//  Created by Марина Чемезова on 07.05.2023.
//

import Foundation

public class Fallback<Primary: FailableQuery, Secondary: FailableQuery>: FailableQuery
    where Primary.Success == Secondary.Success,
        Primary.Failure == Secondary.Failure
{
    public typealias Success = Primary.Success
    public typealias Failure = Primary.Failure
    
    private let primary: Primary
    private let fallback: Secondary
    
    public init(primary: Primary, fallback: Secondary) {
        self.primary = primary
        self.fallback = fallback
    }
    
    public func load(_ completion: @escaping (_ result: Result<Success, Failure>) -> Void) {
        primary.load {[weak self] result in
            guard let self else { return }
            switch result {
            case .failure:
                self.loadFallback(completion)
            default:
                completion(result)
            }
        }
    }
    
    private func loadFallback(_ completion: @escaping (_ result: Result<Success, Failure>) -> Void) {
        fallback.load {[weak self] result in
            guard self != nil else { return }
            completion(result)
        }
    }
    
}
