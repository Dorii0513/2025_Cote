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

    init(repository: NoteRepositoryProtocol) {
        self.repository = repository
    }
    
    @MainActor
    init() {
        self.init(repository: NoteRepository())
    }

    func execute(note: Note) async throws {
        try await repository.saveNote(note: note)
    }
}

