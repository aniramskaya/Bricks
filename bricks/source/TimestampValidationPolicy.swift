//
//  TimestampValidationPolicy.swift
//  bricks
//
//  Created by Марина Чемезова on 08.05.2023.
//

import Foundation

public protocol TimestampValidationPolicy {
    func validate(_: Date?) -> Bool
}
