//
//  DeleteFolderUseCase.swift
//  Cote
//
//  Created by 김예림 on 11/25/25.
//

import Foundation

protocol DeleteFolderUseCase {
    func execute(folderID: UUID) async throws
}

struct DefaultDeleteFolderUseCase: DeleteFolderUseCase {
    private let repository: NoteRepositoryProtocol

    init(repository: NoteRepositoryProtocol) {
        self.repository = repository
    }
    
    @MainActor
    init() {
        self.init(repository: NoteRepository())
    }

    func execute(folderID: UUID) async throws {
        try await repository.deleteFolder(id: folderID)
    }
}
