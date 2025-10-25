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
    private let repository: NoteRepository

    init(repository: NoteRepository) {
        self.repository = repository
    }
    
    @MainActor
    init() {
        self.init(repository: RealmNoteRepository())
    }

    func execute(note: Note) async throws {
        try await repository.createNote(note: note)
    }
}
