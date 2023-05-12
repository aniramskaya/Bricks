//
//  Examples.swift
//  bricksTests
//
//  Created by Марина Чемезова on 12.05.2023.
//

import Foundation
import bricks

enum Examples {
    static func simpleModelLoader() -> any FailableQuery {
        let dto = DTO(value: UUID())
        return DTOLoader(dto: dto).map(with: DTO.toModel)
    }
    
    static func modelLoaderWithInMemoryCache() -> any FailableQuery {
        let dto = DTO(value: UUID())
        
        let storage = InMemoryStorage<Model>().asQuery()
        
        return storage
        .expirable(validationPolicy: TimeIntervalValidationPolicy())
        .fallback(
            DTOLoader(dto: dto)
            .map(with: DTO.toModel)
            .store(into: storage)
        )
    }
    
    static func onceLoadedAlwaysStaysInMind() -> any FailableQuery {
        let dto = DTO(value: UUID())
        
        let storage = InMemoryStorage<Model>().asQuery()
        
        return storage
        .expirable(validationPolicy: TimeIntervalValidationPolicy())
        .fallback(
            DTOLoader(dto: dto)
            .map(with: DTO.toModel)
            .store(into: storage)
            .secondChance(storage)
        )
    }
}
