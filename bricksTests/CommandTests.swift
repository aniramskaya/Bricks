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
    typealias Success = Int
    typealias Failure = NSError

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
            return spy!.map { $0.map { "\($0)" } }
        }
        

        let commandParam = UUID()
        let spyLoadingResult = Result<Int, NSError>.success(87678)

        var commandLoadedResult: Result<String, NSError>?
        let commandExpectedResult = Result<String, NSError>.success("87678")

        let exp = expectation(description: "wait for async to complete")
        sut.execute(commandParam) { result in
            commandLoadedResult = result
            exp.fulfill()
        }
        spy?.complete(with: spyLoadingResult)
        wait(for: [exp], timeout: 1.0)
        
        XCTAssertEqual(spy?.param, commandParam)
        XCTAssertEqual(buildQueryCallCount, 1)
        XCTAssertEqual(spy?.loadCallCount, 1)
        XCTAssertEqual(commandLoadedResult, commandExpectedResult, "Expected \(commandExpectedResult) loaded \(String(describing: commandLoadedResult)) instead")
    }
    
    func test_execute_DoesNotCallCompletionWhenSutDeallocated () throws {
        var spy: CommandQuerySpy?
        var sut: Command<UUID, FailableConverter<CommandQuerySpy, String, CommandQuerySpy.Failure>>? = Command{ (param: UUID) in
            spy = CommandQuerySpy(value: param)
            return spy!.map { $0.map { "\($0)" } }
        }
        
        
        let commandParam = UUID()
        let spyLoadingResult = Result<Int, NSError>.success(87678)
        
        sut?.execute(commandParam) { result in
            XCTFail("Completion should not be called")
        }
        sut = nil
        spy?.complete(with: spyLoadingResult)
    }
    
}
