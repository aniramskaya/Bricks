//
//  CompositionHelpersTests.swift
//  bricksTests
//
//  Created by Марина Чемезова on 09.05.2023.
//

import Foundation
import XCTest
import bricks

struct DTO: Encodable {
    let value: UUID
}

extension DTO {
    static func toModel(_ result: Result<DTO, Error>) -> Result<Model, Error> {
        result.map { Model(value: $0.value.uuidString) }
    }
    
    static func model(_ dto: DTO) -> Model {
        Model(value: dto.value.uuidString)
    }
}

struct Model: Equatable {
    let value: String
}

class DTOLoader: FailableQuery {
    typealias Success = DTO
    typealias Failure = Swift.Error
    
    let dto: DTO
    init(dto: DTO) {
        self.dto = dto
    }
    
    func load(completion: @escaping (Result<Success, Failure>) -> Void) {
        completion(.success(dto))
    }
}

class DTOLoaderNonfailable: Query {
    typealias Result = DTO
    
    let dto: DTO
    init(dto: DTO) {
        self.dto = dto
    }
    
    func load(completion: @escaping (DTO) -> Void) {
        completion(dto)
    }
}


class CompositionHelpersTests: XCTestCase {
    func test_dtoIsConvertedToModel() throws {
        let (dto, model) = matchingDTOAndModel()
        let sut = DTOLoader(dto: dto).map(with: DTO.toModel)

        expect(sut: sut, toCompleteWith: .success(model))
    }
    
    func test_modelIsStored() throws {
        let (dto, model) = matchingDTOAndModel()
        let storage = InMemoryStorage<Model>().asQuery()
        
        let sut = DTOLoader(dto: dto)
        .map(with: DTO.toModel)
        .store(into: storage)
        
        expect(sut: sut, toCompleteWith: .success(model))

        storage.load { result in
            XCTAssertEqual(try? result.get(), model)
        }
    }
    
    func test_nonFailableQueryConvert() throws {
        let (dto, model) = matchingDTOAndModel()
        let sut = DTOLoaderNonfailable(dto: dto).convert(map: DTO.model)
        
        sut.load { result in
            XCTAssertEqual(result, model)
        }
    }
    
    func test_synchronousStorageAdapter() throws {
        let model1 = Model(value: UUID().uuidString)
        let model2 = Model(value: UUID().uuidString)

        let storage = InMemoryStorage<Model>()
        let sut = storage.asQuery()
        
        sut.save(value: model1, completion: { _ in })
        XCTAssertEqual(storage.load(), model1)
        
        storage.save(model2)
        expect(sut: sut, toCompleteWith: .success(model2))
        
        sut.clear(completion: { _ in })
        expect(sut: sut, toCompleteWith: .failure(StorageError.empty))
    }
    
    func test_fallback() throws {
        let model = Model(value: UUID().uuidString)
        let storage1 = InMemoryStorage<Model>().asQuery()
        let storage2 = InMemoryStorage<Model>().asQuery()
        storage2.save(value: model, completion: { _ in })
        
        let sut = storage1.fallback(storage2)
        
        expect(sut: sut, toCompleteWith: .success(model))
    }
    
    func test_secondChance() throws {
        let model = Model(value: UUID().uuidString)
        let storage1 = InMemoryStorage<Model>().asQuery()
        let storage2 = InMemoryStorage<Model>().asQuery()
        storage2.save(value: model, completion: { _ in })
        
        let sut = storage1.secondChance(storage2)
        
        expect(sut: sut, toCompleteWith: .success(model))
    }
    
    func test_expirableCache() throws {
        let model1 = Model(value: UUID().uuidString)
        let model2 = Model(value: UUID().uuidString)

        let storage = InMemoryStorage<Model>()
        let sut = storage.asQuery().expirable(validationPolicy: TimeIntervalValidationPolicy())
        
        storage.save(model1)
        expect(sut: sut, toCompleteWith: .success(model1))

        storage.save(model2)
        expect(sut: sut, toCompleteWith: .success(model2))
        
        storage.clear()
        expect(sut: sut, toCompleteWith: .failure(StorageError.empty))
    }

    func test_notifyingCache() throws {
        let storage = InMemoryStorage<Model>().asQuery()

        var onSuccessCount = 0
        var onFailureCount = 0
        let sut = storage.notify(onSuccess: { _ in onSuccessCount += 1}, onFailure: { _ in onFailureCount += 1})
        
        expect(sut: sut, toCompleteWith: .failure(StorageError.empty))
        XCTAssertEqual(onSuccessCount, 0)
        XCTAssertEqual(onFailureCount, 1)
        
        let string = UUID().uuidString
        storage.save(value: .init(value: string), completion: { _ in })
        expect(sut: sut, toCompleteWith: .success(.init(value: string)))
        XCTAssertEqual(onSuccessCount, 1)
        XCTAssertEqual(onFailureCount, 1)
    }

    
    private func matchingDTOAndModel() -> (DTO, Model) {
        let uuid = UUID()
        let dto = DTO(value: uuid)
        let model = Model(value: uuid.uuidString)

        return (dto, model)
    }
    
    private func expect<SUT: FailableQuery>(sut: SUT, toCompleteWith expectedResult: Result<Model, Error>, file: StaticString = #filePath, line: UInt = #line) where SUT.Success == Model, SUT.Failure == Error {
        
        let exp = expectation(description: "Wait for async query to complete")
        sut.load { (result: Result<Model, Error>) in
            switch (result, expectedResult) {
            case let (.success(received), .success(expected)):
                XCTAssertEqual(received, expected, file: file, line: line)
            case let (.failure(received), .failure(expected)):
                XCTAssertEqual(received as NSError, expected as NSError, file: file, line: line)
            default:
                XCTFail("Expected \(expectedResult) got \(result) instead", file: file, line: line)
            }
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)
    }

}

class TimeIntervalValidationPolicy: TimestampValidationPolicy {
    func validate(_: Date?) -> Bool {
        return true
    }
}
