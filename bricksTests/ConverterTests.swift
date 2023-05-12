//
//  bricksTests.swift
//  bricksTests
//
//  Created by Марина Чемезова on 07.05.2023.
//

import XCTest
import bricks

final class ConverterTests: XCTestCase {
    func test_converter_doesNotMessageUponCreation() throws {
        let (_, spy) = makeSUT()
        
        XCTAssertEqual(spy.messages, [])
    }
    
    func test_load_callsLoad() throws {
        let (sut, spy) = makeSUT()
        
        sut.load { _ in }
        
        XCTAssertEqual(spy.messages, [.load])
    }
    
    func test_load_convertsModel() throws {
        let (sut, spy) = makeSUT()
        let (source, target) = makeCompatibleSourceTarget()
        
        let exp = expectation(description: "wait for loading complete")
        var loadedResult: TargetModel?
        sut.load { result in
            loadedResult = result
            exp.fulfill()
        }
        spy.completeLoading(with: source)
        
        wait(for: [exp], timeout: 1.0)
        XCTAssertEqual(target, loadedResult)
        XCTAssertEqual(spy.messages, [.load, .map(source)])
    }
    
    func test_load_doesNotCallCompletionAfterBeingDeallocated() {
        var (sut, spy): (Converter<QuerySpy, TargetModel>?, QuerySpy)  = makeSUT()
        
        var completionCallCount = 0
        sut?.load { _ in
            completionCallCount += 1
        }
        sut = nil
        spy.completeLoading(with: SourceModel.any())
        
        RunLoop.main.run(until: Date())

        XCTAssertEqual(spy.messages, [.load,])
        XCTAssertEqual(completionCallCount, 0)
    }

    // MARK: Private
    
    private func makeSUT(file: StaticString = #filePath, line: UInt = #line) -> (Converter<QuerySpy, TargetModel>, QuerySpy) {
        let spy = QuerySpy()
        let converter = Converter(query: spy, map: spy.map)
        
        trackForMemoryLeaks(converter, file: file, line: line)
        trackForMemoryLeaks(spy, file: file, line: line)
        return (converter, spy)
    }
    
    private func makeCompatibleSourceTarget() -> (SourceModel, TargetModel) {
        let uuid = UUID()
        return (SourceModel(value: uuid), TargetModel(value: uuid.uuidString))
    }
}

private struct SourceModel: Equatable {
    let value: UUID
}

private extension SourceModel {
    static func any() -> SourceModel {
        return SourceModel(value: UUID())
    }
}

private struct TargetModel: Equatable {
    let value: String
}

private class QuerySpy: Query {
    enum Message: Equatable {
        case load
        case map(SourceModel)
    }
    
    var messages: [Message] = []
    var completions: [(SourceModel) -> Void] = []
    
    func load(completion: @escaping (SourceModel) -> Void) {
        messages.append(.load)
        completions.append(completion)
    }
    
    func completeLoading(with result: SourceModel, at index: Int = 0) {
        completions[index](result)
    }
    
    func map(_ source: SourceModel) -> TargetModel {
        messages.append(.map(source))
        return TargetModel(value: source.value.uuidString)
    }
}
