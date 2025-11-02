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
    private let threshold: Double = 0.2

    init(repository: NoteRepositoryProtocol) {
        self.repository = repository
    }
    
    @MainActor
    init() {
        self.init(repository: NoteRepository())
    }

    func execute(query: String, topK: Int = 50) async throws -> [SearchResult] {
        
        // 한국어용 벡터 공간 로드
        guard let embedding = NLEmbedding.wordEmbedding(for: .english) else {
            print("⚠️ 한국어 임베딩 로드 실패")
            return []
        }
        
        // limit 제한 없이 가져옴 - 추후 수정 가능성 있
        let notes = try await repository.fetchNoteLight(limit: nil)
        var results: [SearchResult] = []

        for note in notes {
            let (id, title, content) = note
            
            // 벡터 거리 계산
            let distance = averageDistance(between: query, and: content, using: embedding)
            let similarity = max(0, 1 - (distance / 2))
            
            print("📄 \(title) → distance:", distance)
            
            // 점수 필터링
            if similarity >= threshold {
                let preview = String(content.prefix(160))
                results.append(
                    SearchResult(noteID: id, title: title, preview: preview, score: similarity)
                )
            }
        }
        
        print("🟡 Embedding loaded:", embedding.dimension)
        print("🔍 Query:", query)
        
        // 정렬해서 반환
        return results.sorted { $0.score > $1.score }
    }
    
    func averageDistance(between query: String, and content: String, using embedding: NLEmbedding) -> Double {
        let queryTokens = query.lowercased().split(separator: " ")
        let contentTokens = content.lowercased().split(separator: " ")
        
        var distances: [Double] = []
        for q in queryTokens {
            for c in contentTokens {
                let d = embedding.distance(between: String(q), and: String(c))
                if d < 2.0 { // 유효 거리만 추가
                    distances.append(d)
                }
            }
        }
        return distances.isEmpty ? 2.0 : distances.reduce(0, +) / Double(distances.count)
    }
}
