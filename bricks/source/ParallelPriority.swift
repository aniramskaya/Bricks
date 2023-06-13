//
//  ParallelPriority.swift
//  Widgets
//
//  Created by Марина Чемезова on 12.06.2023.
//

import Foundation

public enum ParallelPriority {
    case required
    case custom(UInt)
    case optional
    
    func value() -> UInt {
        switch self {
        case .required: return UInt.max
        case .optional: return UInt.min
        case let.custom(value): return value
        }
    }
}

extension ParallelPriority: Comparable {
    public static func > (lhs: Self, rhs: Self) -> Bool {
        return lhs.value() > rhs.value()
    }
    
    public static func >= (lhs: Self, rhs: Self) -> Bool {
        return lhs.value() >= rhs.value()
    }
    
    public static func < (lhs: Self, rhs: Self) -> Bool {
        return lhs.value() < rhs.value()
    }
    
    public static func <= (lhs: Self, rhs: Self) -> Bool {
        return lhs.value() <= rhs.value()
    }
    
    public static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.value() == rhs.value()
    }
}
