import NaturalLanguage
import Foundation

protocol searchUseCase {
    func execute(query: String, topK: Int, mode: SearchMode) async throws -> [SearchResult]
}

struct DefaultSearchUseCase: searchUseCase {
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
    
    func execute(query: String, topK: Int = 200, mode: SearchMode) async throws -> [SearchResult] {
        
        if query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return []
        }
        // 검색어 임베딩 계산
        let queryVec = try embeddingModel.embedding(for: "query: \(query) 코드")
        
        // 노트 목록 가져오기
        let notes = try await repository.fetchNoteLight(limit: topK)

        var results: [SearchResult] = []
        
        for (id, title, content, folders, updatedAt, tags, embF) in notes {
            guard let embF, !embF.isEmpty else { continue }
            let noteVec = embF.map { Double($0) }
            let similarity = cosineSimilarity(queryVec, noteVec)
            let lengthPenalty = calculateLengthPenalty(contentLength: content.count)
            
            // 제목 매칭 점수
            let titleBonus = calculateTitleBonus(query: query, title: title)
            
            // 키워드 매칭 점수
//            let keywordBonus = calculateKeywordBonus(query: query, content: content)
            
            // 최종 점수
            let adjusted = similarity * lengthPenalty + titleBonus
            
            // semanticSearch
            if mode == .semantic {
                if adjusted >= threshold {
                    results.append(
                        SearchResult(
                            noteID: id,
                            title: title,
                            content: content,
                            folders: folders,
                            updatedAt: updatedAt,
                            tags: tags,
                            score: adjusted
                        )
                    )
                }
                
             // keywordSearch
            } else {
                results.append(
                    SearchResult(
                        noteID: id,
                        title: title,
                        content: content,
                        folders: folders,
                        updatedAt: updatedAt,
                        tags: tags,
                        score: adjusted
                    )
                )
            }
        }
        
        return results
    }
    
    // MARK: - Scoring Helpers
    
    private func calculateLengthPenalty(contentLength: Int) -> Double {
        let normalizedLength = Double(contentLength) / 200.0
        return min(1.0, max(0.85, 0.85 + (normalizedLength * 0.15)))
    }
    
    // 제목 매칭
    private func calculateTitleBonus(query: String, title: String) -> Double {
        let queryTokens = tokenize(query)
        let titleLower = title.lowercased()
        
        let matches = queryTokens.filter { token in
            titleLower.contains(token.lowercased())
        }
        if queryTokens.isEmpty { return 0.0 }
        // 최대 0.05 보너스를 줌
        return Double(matches.count) / Double(queryTokens.count) * 0.05
    }
    
    // 키워드 매칭
    private func calculateKeywordBonus(query: String, content: String) -> Double {
        let queryTokens = tokenize(query)
        let previewLower = content.lowercased()
        
        let matches = queryTokens.filter { token in
            previewLower.contains(token.lowercased())
        }
        // 최대 0.08 보너스를 줌
        if queryTokens.isEmpty { return 0.0 }
        return Double(matches.count) / Double(queryTokens.count) * 0.08
    }
    
    private func tokenize(_ text: String) -> [String] {
        let components = text.components(separatedBy: .whitespacesAndNewlines)
        return components
            .map { $0.trimmingCharacters(in: .punctuationCharacters) }
            .filter { !$0.isEmpty && $0.count > 1 }
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
