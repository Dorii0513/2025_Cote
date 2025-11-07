//
//  CreateNoteUseCase.swift
//  Cote
//
//  Created by 김예림 on 10/7/25.
//

import Foundation

protocol CreateNoteUseCase {
    func execute(note: Note) async throws
}

struct DefaultCreateNoteUseCase: CreateNoteUseCase {
    private let repository: NoteRepositoryProtocol

    init(repository: NoteRepositoryProtocol) {
        self.repository = repository
    }
    
    @MainActor
    init() {
        self.init(repository: NoteRepository())
    }

    func execute(note: Note) async throws {
        try await repository.createNote(note: note)
    }
}
