//
//  SearchNoteUseCase.swift
//  Cote
//
//  Created by 김예림 on 11/1/25.
//

import NaturalLanguage
import Foundation

protocol SearchUseCase {
    func execute(query: String, topK: Int) async throws -> [SearchResult]
}

struct DefaultSearchUseCase: SearchUseCase {
    private let repository: NoteRepositoryProtocol
    private let threshold: Double = 0.4

    init(repository: NoteRepositoryProtocol) {
        self.repository = repository
    }
    
    @MainActor
    init() {
        self.init(repository: NoteRepository())
    }

    func execute(query: String, topK: Int = 50) async throws -> [SearchResult] {
        
        // 한국어용 벡터 공간 로드
        guard let embedding = NLEmbedding.wordEmbedding(for: .korean) else {
            print("⚠️ 한국어 임베딩 로드 실패")
            return []
        }
        
        // limit 제한 없이 가져옴 - 추후 수정 가능성 있
        let notes = try await repository.fetchNoteLight(limit: nil)
        var results: [SearchResult] = []

        for note in notes {
            let (id, title, content) = note
            
            // 벡터 거리 계산
            let distance = embedding.distance(between: query, and: content)
            let similarity = 1 - distance
            
            // 점수 필터링
            if similarity >= threshold {
                let preview = String(content.prefix(160))
                results.append(
                    SearchResult(noteID: id, title: title, preview: preview, score: similarity)
                )
            }
        }
        
        // 정렬해서 반환
        return results.sorted { $0.score > $1.score }
    }
}
