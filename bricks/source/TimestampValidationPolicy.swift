//
//  TimestampValidationPolicy.swift
//  bricks
//
//  Created by Марина Чемезова on 08.05.2023.
//

import Foundation

/// Validates the timestamp using a validation policy.
///
/// This protocol is an abstraction to hide implementation details of how timestamp should be validated. Different code have different needs so it may want to validate the timestamp against time interval in seconds or number of hours or days passed since timestamp.
public protocol TimestampValidationPolicy {
    /// Validates the timestamp according to the policy implemented in an entity conforming to ``TimestampValidationPolicy``
    ///
    /// - Returns: **true** if the timestamp is considered to be valid and **false** otherwise.
    func validate(_: Date?) -> Bool
}
