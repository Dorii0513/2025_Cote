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
    private let threshold: Double = 0.6 // e5는 0.6~0.7이 적당
    private let embeddingModel = E5EmbeddingModel()
    
    
    init(repository: NoteRepositoryProtocol) {
        self.repository = repository
    }
    
    @MainActor
    init() {
        self.init(repository: NoteRepository())
    }
    
    func execute(query: String, topK: Int = 200) async throws -> [SearchResult] {
        // 1️⃣ 모든 노트 가져오기
        let notes = try await repository.fetchNoteLight(limit: topK)
        var results: [SearchResult] = []
        
        // 2️⃣ 쿼리 임베딩 계산
        let queryVec = try embeddingModel.embedding(for: "query: \(query)")
        
        // 3️⃣ 각 노트별 임베딩 비교
        for note in notes {
            let (id, title, content) = note
            let passageVec = try embeddingModel.embedding(for: "passage: \(content)")
            let similarity = cosineSimilarity(queryVec, passageVec)
            
            if similarity >= threshold {
                let preview = String(content.prefix(160))
                results.append(
                    SearchResult(noteID: id, title: title, preview: preview, score: similarity)
                )
            }
        }
        
        // 4️⃣ 점수 순 정렬
        return results.sorted { $0.score > $1.score }
    }
    
    // MARK: - Cosine Similarity
    private func cosineSimilarity(_ a: [Double], _ b: [Double]) -> Double {
        guard a.count == b.count else { return 0 }
        let dot = zip(a, b).map(*).reduce(0, +)
        let magA = sqrt(a.map { $0 * $0 }.reduce(0, +))
        let magB = sqrt(b.map { $0 * $0 }.reduce(0, +))
        return dot / (magA * magB)
    }
}
