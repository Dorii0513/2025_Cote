//
//  DeleteTagUseCAse.swift
//  Cote
//
//  Created by 김예림 on 11/26/25.
//

import Foundation

protocol DeleteTagUseCase {
    func execute(noteID: UUID, tagName: String ) async throws
}

struct DefaultDeleteTagUseCase: DeleteTagUseCase {
    private let repository: NoteRepositoryProtocol

    init(repository: NoteRepositoryProtocol) {
        self.repository = repository
    }
    
    @MainActor
    init() {
        self.init(repository: NoteRepository())
    }

    func execute(noteID: UUID, tagName: String ) async throws {
        try await repository.deleteTag(noteID: noteID, tagName: tagName)
    }
}
