//
//  NoteRepository.swift
//  Cote
//
//  Created by 김예림 on 10/6/25.
//

import Foundation

protocol NoteRepository {
    func itemStream() -> AsyncStream<[NoteItems]>
    func noteStream(id: UUID) -> AsyncStream<Note?>
    
    func save(note: Note) async throws
    func create(note: Note) async throws
    func fetchAllSortedByDateDesc() async throws -> [Note]
    func fetchNote(by id: UUID) async throws -> Note?
    func delete(id: UUID) async throws
}
