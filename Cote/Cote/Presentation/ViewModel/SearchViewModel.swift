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
    
    @Published var filter: SearchFilter = .note
    @Published var mode: SearchMode = .keyword
    @Published var sort: SearchSort = .newest
    
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
                    await self.search(for: newValue)
                    if self.mode == .keyword {
                        self.applyFilter()
                    }
                    self.resultCount = self.results.count
                    self.applySort()
                }
            }
            .store(in: &cancellables)
    }
    
    func cleanQuery() {
        query = ""
    }
    
    func search(for text: String) async {
        do {
            let res = try await useCase.execute(query: text, topK: 200, mode: mode)
            results = res
            UserDefaults.standard.set(self.query, forKey: "Search")
        } catch {
            print("❌ 검색 오류:", error)
            results = []
        }
    }
    
    func setSort(_ newSort: SearchSort) {
        sort = newSort
        applySort()
    }
    
    private func applySort() {
        switch sort {
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
    
    private func applyFilter() {
        switch filter {
        case .note:
            results = results.filter { $0.title.localizedStandardContains(query) }
        case .tag:
            results = results.filter { $0.tags.contains(query) }
        case .content:
            results = results.filter { $0.content.localizedStandardContains(query) }
        }
    }
    
    func toggleSearchMode() {
        mode = (mode == .keyword) ? .semantic : .keyword
        sort = (mode == .keyword) ? .newest : .relevance
        
        // 바뀐 모드에서 다시 검색
        Task {
            await search(for: query)
            if mode == .keyword {
                applyFilter()
            }
            applySort()
            resultCount = results.count
        }
    }
}

enum SearchSort: String {
    case newest = "Newest"
    case oldest = "Oldest"
    case relevance = "Relevance"
}

enum SearchMode {
    case keyword
    case semantic
}

enum SearchFilter: String {
    case note = "Title"
    case tag = "Tag"
    case content = "Content"
}
