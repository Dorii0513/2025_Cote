//
//  UpdateFolderUseCase'.swift
//  Cote
//
//  Created by 김예림 on 11/25/25.
//

import Foundation

protocol UpdateFolderUseCase {
    func execute(id: UUID, newName: String) async throws
}

struct DefaultUpdateFolderUseCase: UpdateFolderUseCase {
    private let repository: NoteRepositoryProtocol

    init(repository: NoteRepositoryProtocol) {
        self.repository = repository
    }
    
    @MainActor
    init() {
        self.init(repository: NoteRepository())
    }

    func execute(id: UUID, newName: String) async throws {
        try await repository.updateFolderName(id: id, name: newName)
    }
}
