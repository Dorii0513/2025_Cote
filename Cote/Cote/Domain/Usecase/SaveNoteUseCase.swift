//
//  SaveNoteUseCase.swift
//  Cote
//
//  Created by 김예림 on 10/6/25.
//

import Foundation

protocol SaveNoteUseCase {
    func execute(note: Note) async throws
}

struct DefaultSaveNoteUseCase: SaveNoteUseCase {
    private let repository: NoteRepositoryProtocol
    private let embeddingModel = E5EmbeddingModel()

    init(repository: NoteRepositoryProtocol) {
        self.repository = repository
    }
    
    @MainActor
    init() {
        self.init(repository: NoteRepository())
    }

    func execute(note: Note) async throws {
        print("🔥 execute() called")
        
        let summarizer = CodeSummarizer()
        let summary = try await summarizer.summarize(code: note.content)

        
        // 임베딩 생성
        let text = "passage: \(note.title), \(summary)"
        let emb = try embeddingModel.embedding(for: text)
        let vecF = emb.map { Float($0) }
        
        // 임베딩 note에 붙여서 저장
        var noteWithEmbedding = note
        noteWithEmbedding.embedding = vecF
        
        // 저장
        try await repository.saveNote(note: noteWithEmbedding)
    }
}

