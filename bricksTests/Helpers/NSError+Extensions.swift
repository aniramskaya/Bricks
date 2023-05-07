//
//  NSError+Extensions.swift
//  bricksTests
//
//  Created by Марина Чемезова on 07.05.2023.
//

import Foundation

extension NSError {
    static func any() -> NSError {
        NSError(domain: UUID().uuidString, code: Int.random(in: 1...1000))
    }
}
