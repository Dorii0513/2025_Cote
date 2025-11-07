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
    private let useCase: SearchUseCase
    
    @Published var query: String = ""
    @Published private(set) var results: [SearchResult] = []

    
    private var cancellables = Set<AnyCancellable>()

    init(usecase: SearchUseCase){
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
                Task { await self.search(for: newValue) }
            }
            .store(in: &cancellables)
    }

    func search(for text: String) async {
        do {
            let res = try await useCase.execute(query: text, topK: 200)
            results = res
        } catch {
            print("❌ 검색 오류:", error)
            results = []
        }
    }
}
