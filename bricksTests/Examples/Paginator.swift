//
//  Paginator.swift
//  bricksTests
//
//  Created by Марина Чемезова on 05.06.2023.
//

import Foundation
import bricks

struct ListItem: Hashable {
    let sort: String
    let page: Int
    let value: UUID
}

class ListLoader: ListFailableQuery {
    typealias Element = ListItem
    typealias Failure = Swift.Error
    
    var page: Int
    var sort: String
    var shouldFail: Bool
    
    init(page: Int, sort: String, shouldFail: Bool = false) {
        self.page = page
        self.sort = sort
        self.shouldFail = shouldFail
    }
    
    func load(completion: @escaping (Result<[Element], Failure>) -> Void) {
        if shouldFail {
            completion(.failure(NSError.any()))
        } else {
            completion(.success([Element(sort: sort, page: page, value: .init())]))
        }
    }
}

extension ListLoader {
    static func paginated(sortOrder: String) -> Paginator<ListLoader> {
        return Paginator { pageNumber in
            return ListLoader(page: pageNumber, sort: sortOrder)
        }
    }
    
    static func failingPaginated(sortOrder: String) -> Paginator<ListLoader> {
        return Paginator { pageNumber in
            return ListLoader(page: pageNumber, sort: sortOrder, shouldFail: true)
        }
    }
}

protocol ListPresenter {
    func displayLoading()
    func display(_ result: Result<([ListItem], Bool), Error>)
}

class ListInteractor {
    let sortOrders = ["A-Z", "Z-A"]
    let presenter: ListPresenter

    var currentLoader: Paginator<ListLoader>
    
    init(presenter: ListPresenter) {
        self.presenter = presenter
        self.currentLoader = ListLoader.paginated(sortOrder: sortOrders[0])
    }
    
    func load() {
        presenter.displayLoading()
        currentLoader.load { [weak self] result in
            self?.presenter.display(result)
        }
    }
    
    func loadMore() {
        presenter.displayLoading()
        currentLoader.loadMore { [weak self] result in
            self?.presenter.display(result)
        }
    }
    
    func applySort(_ sort: String){
        let newLoader = ListLoader.failingPaginated(sortOrder: sort)
        presenter.displayLoading()
        newLoader.load { [weak self] result in
            guard let self else { return }
            switch result {
            case .failure:
                self.load()
            default:
                self.currentLoader = newLoader
                self.presenter.display(result)
            }
        }
    }
}
