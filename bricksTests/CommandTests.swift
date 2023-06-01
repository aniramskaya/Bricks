//
//  CommandTests.swift
//  bricksTests
//
//  Created by Марина Чемезова on 31.05.2023.
//

import Foundation
import XCTest
import bricks

class CommandQuerySpy: FailableQuery {
    typealias Success = String
    typealias Failure = Swift.Error

    let param: UUID
    init(value: UUID) {
        self.param = value
    }
    
    var completions: [(Result<Success, Failure>) -> Void] = []
    var loadCallCount = 0
    func load(completion: @escaping (Result<Success, Failure>) -> Void) {
        loadCallCount += 1
        completions.append(completion)
    }
    
    func complete(with result: Result<Success, Failure>, at index: Int = 0) {
        completions[index](result)
    }
}

class CommandTests: XCTestCase {
    func test_init_doesNotMessage() throws {
        var buildQueryCallCount = 0
        let _ = Command{ (param: UUID) in
            buildQueryCallCount += 1
            return CommandQuerySpy(value: param)
        }
        
        XCTAssertEqual(buildQueryCallCount, 0)
    }
    
    func test_execute_BuildsQueryAndCallsLoad () throws {
        var buildQueryCallCount = 0
        var spy: CommandQuerySpy?
        let sut = Command{ (param: UUID) in
            buildQueryCallCount += 1
            spy = CommandQuerySpy(value: param)
            return spy!
        }
        
        let param = UUID()
        let expectedResult = "qwe"

        let exp = expectation(description: "wait for async to complete")
        sut.execute(param) { result in
            switch result {
            case let .success(loadedResult):
                XCTAssertEqual(loadedResult, expectedResult, "Expected \(expectedResult) loaded \(loadedResult) instead")
            default:
                XCTFail("Expected .success loaded \(result) instead")
            }
            exp.fulfill()
        }
        spy?.complete(with: .success("qwe"))
        wait(for: [exp], timeout: 1.0)
        
        XCTAssertEqual(buildQueryCallCount, 1)
        XCTAssertEqual(spy?.loadCallCount, 1)
    }
    
}
