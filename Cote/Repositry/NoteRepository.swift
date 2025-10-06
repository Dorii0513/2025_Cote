//
//  NoteRepository.swift
//  Cote
//
//  Created by 김예림 on 10/6/25.
//

import Foundation

protocol NoteRepository {
    func save(note: Note) async throws
    func fetchAllSortedByDateDesc() async throws -> [Note]
    func delete(id: UUID) async throws
}
