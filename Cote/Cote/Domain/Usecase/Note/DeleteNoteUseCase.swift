//
//  DeleteNoteUseCase.swift
//  Cote
//
//  Created by 김예림 on 11/22/25.
//

import Foundation

protocol DeleteNoteUseCase {
    func execute(id: UUID) async throws
}

struct DefaultDeleteNoteUseCase: DeleteNoteUseCase {
    private let repository: NoteRepositoryProtocol

    init(repository: NoteRepositoryProtocol) {
        self.repository = repository
    }
    
    @MainActor
    init() {
        self.init(repository: NoteRepository())
    }

    func execute(id: UUID) async throws {
        try await repository.deleteNote(id: id)
    }
}
