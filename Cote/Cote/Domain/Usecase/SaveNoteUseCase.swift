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
    private let repository: NoteRepository

    init(repository: NoteRepository) {
        self.repository = repository
    }
    
    @MainActor
    init() {
        self.init(repository: RealmNoteRepository())
    }

    func execute(note: Note) async throws {
        try await repository.save(note: note)
    }
}

