//
//  Loader.swift
//  bricks
//
//  Created by Марина Чемезова on 07.05.2023.
//

/// Basic protocol which declares asynchronous load for any data
public protocol Query {
    associatedtype Result

    func load(_ completion: @escaping (Result) -> Void)
}
