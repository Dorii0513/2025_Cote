//
//  CreateFolderUseCase.swift
//  Cote
//
//  Created by 김예림 on 10/14/25.
//

import Foundation

protocol CreateFolderUseCase {
    func execute(name: String, parentID: UUID?) async throws -> UUID
}

struct DefaultCreateFolderUseCase: CreateFolderUseCase {
    private let repository: NoteRepositoryProtocol

    init(repository: NoteRepositoryProtocol) {
        self.repository = repository
    }
    
    @MainActor
    init() {
        self.init(repository: NoteRepository())
    }

    func execute(name: String, parentID: UUID?) async throws -> UUID {
        try await repository.createFolder(name: name, parentID: parentID)
    }
}
