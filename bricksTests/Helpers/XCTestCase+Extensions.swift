//
//  XCTestCase+Extensions.swift
//  bricksTests
//
//  Created by Марина Чемезова on 07.05.2023.
//

import XCTest

extension XCTestCase {
    func trackForMemoryLeaks(_ object: AnyObject, file: StaticString = #filePath, line: UInt = #line) {
        addTeardownBlock { [weak object] in
            XCTAssertNil(object, "Object has not been deallocated. Potential memory leak.", file: file, line: line)
        }
    }
}

