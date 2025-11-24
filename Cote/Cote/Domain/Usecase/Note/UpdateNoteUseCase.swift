//
//  SaveNoteUseCase.swift
//  Cote
//
//  Created by 김예림 on 10/6/25.
//

import Foundation

protocol UpdateNoteUseCase {
    func execute(id: UUID, save: NoteSaveField) async throws
}

struct DefaultUpdateNoteUseCase: UpdateNoteUseCase {
    private let repository: NoteRepositoryProtocol
    private let embeddingModel = E5EmbeddingModel()

    init(repository: NoteRepositoryProtocol) {
        self.repository = repository
    }
    
    @MainActor
    init() {
        self.init(repository: NoteRepository())
    }

    func execute(id: UUID, save: NoteSaveField) async throws {
        switch save {
        case .title(let newTitle):
            try await repository.updateNoteTitle(id: id, title: newTitle)
            
        case .content(let newContent):
            let summarizer = CodeSummarizer()
            let summary = try await summarizer.summarize(code: newContent)
            
            // 임베딩 생성
            let text = "passage: \(summary)"
            let data = try embeddingModel.embedding(for: text)
                .map(Float.init)
                .withUnsafeBufferPointer(Data.init)
            
            try await repository.updateNoteContent(id: id, content: newContent, embadding: data)
            
        case .tags(let newTags):
            try await repository.updateNoteTags(id: id, tags: newTags)
            
        case .language(let newLanguage):
            try await repository.updateNoteLanguage(id: id, language: newLanguage)
        }
    }
}

enum NoteSaveField {
    case title(String)
    case content(String)
    case tags([Tag])
    case language(String)
}
