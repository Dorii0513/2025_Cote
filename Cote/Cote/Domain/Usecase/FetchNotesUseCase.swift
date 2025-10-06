//
//  FetchNotesUseCase.swift
//  Cote
//
//  Created by 김예림 on 10/6/25.
//

import Foundation

protocol FetchNotesUseCase {
    func execute() async throws -> [Note]
}

@MainActor
struct DefaultFetchNotesUseCase: FetchNotesUseCase {
    private let repository: NoteRepository

    init(repository: NoteRepository) {
        self.repository = repository
    }

    init() {
        self.init(repository: RealmNoteRepository())
    }

    func execute() async throws -> [Note] {
        try await repository.fetchAllSortedByDateDesc()
    }
}

