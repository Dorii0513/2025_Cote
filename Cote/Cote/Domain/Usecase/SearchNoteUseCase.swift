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
    private let threshold: Double = 0.85
    private let embeddingModel = E5EmbeddingModel()
    
    
    init(repository: NoteRepositoryProtocol) {
        self.repository = repository
    }
    
    @MainActor
    init() {
        self.init(repository: NoteRepository())
    }
    
    func execute(query: String, topK: Int = 200) async throws -> [SearchResult] {
        // 임베딩 계산 (검색어)
        let queryVec = try embeddingModel.embedding(for: "query: \(query)")

        // 노트 목록 가져오기
        let notes = try await repository.fetchNoteLight(limit: topK)

        // 임베딩과 노트 유사도 계산
        var results: [SearchResult] = []
        for (id, title, preview, embF) in notes {
            guard let embF, !embF.isEmpty else { continue }
            let noteVec = embF.map { Double($0) }
            let similarity = cosineSimilarity(queryVec, noteVec)

            // 길이 보정?
            let lengthPenalty = min(1.0, max(0.6, Double(preview.count) / 200.0))
            let adjusted = similarity * lengthPenalty

            if adjusted >= threshold {
                results.append(
                    SearchResult(
                        noteID: id,
                        title: title,
                        preview: preview,
                        score: adjusted
                    )
                )
            }
        }

        // 정렬 (유사도 높은 순)
        return results.sorted { $0.score > $1.score }
    }
    
    // MARK: - Cosine Similarity
    private func cosineSimilarity(_ a: [Double], _ b: [Double]) -> Double {
        let n = min(a.count, b.count)
        guard n > 0 else { return 0.0 }

        var dot = 0.0
        var normA = 0.0
        var normB = 0.0

        for i in 0..<n {
            let ai = a[i]
            let bi = b[i]
            dot += ai * bi
            normA += ai * ai
            normB += bi * bi
        }

        let denom = sqrt(normA) * sqrt(normB)
        if denom == 0 || denom.isNaN || denom.isInfinite {
            return 0.0
        }
        return dot / denom
    }
}

