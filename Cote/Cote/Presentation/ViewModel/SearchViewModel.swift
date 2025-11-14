//
//  SearchViewModel.swift
//  Cote
//
//  Created by 김예림 on 11/1/25.
//

import SwiftUI
import Combine

@MainActor
final class SearchViewModel: ObservableObject {
    private let useCase: searchUseCase
    
    @Published var query: String = (UserDefaults.standard.string(forKey: "Search") ?? "")
    @Published var resultCount: Int = 0
    @Published private(set) var results: [SearchResult] = []
    @Published var filter: SearchFilter = .relevance

    
    private var cancellables = Set<AnyCancellable>()

    init(usecase: searchUseCase){
        self.useCase = usecase
        observeQuery()
    }
    
    convenience init() {
        self.init(usecase: DefaultSearchUseCase())
    }

    // 검색어 실시간 감시
    private func observeQuery() {
        $query
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main) // 과도한 호출 방지
            .removeDuplicates()
            .sink { [weak self] newValue in
                guard let self else { return }
                Task {
                    await self.semanticSearch(for: newValue)
                    self.applyFilter()
                }
            }
            .store(in: &cancellables)
    }
    
    func cleanQuery() {
        query = ""
    }
    
    func keywordSearch(for text: String) async {
        do {
            
        } catch {
            
        }
    }

    func semanticSearch(for text: String) async {
        do {
            let res = try await useCase.execute(query: text, topK: 200)
            results = res
            resultCount = res.count
            UserDefaults.standard.set(self.query, forKey: "Search")
        } catch {
            print("❌ 검색 오류:", error)
            results = []
        }
    }
    
    func setFilter(_ newFilter: SearchFilter) {
        filter = newFilter
        applyFilter()
    }
    
    private func applyFilter() {
        switch filter {
        case .newest:
            results.sort { lhs, rhs in
                lhs.updatedAt > rhs.updatedAt
            }
        case .oldest:
            results.sort { lhs, rhs in
                lhs.updatedAt < rhs.updatedAt
            }
        case .relevance:
            results.sort { lhs, rhs in
                lhs.score > rhs.score
            }
        }
    }
}

enum SearchFilter: String {
    case newest = "Newest"
    case oldest = "Oldest"
    case relevance = "Relevance"
}

enum SearchMode {
    case keyword
    case semantic
}
