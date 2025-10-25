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
    func delete(id: UUID) async throws
    
    func createNote(note: Note) async throws
    func fetchNote(by id: UUID) async throws -> Note?
    func moveNote(noteID: UUID, toFolderID: UUID) async throws
    func moveNoteToRoot(noteID: UUID) async throws
    
    func createFolder(name: String, parentID: UUID?) async throws -> UUID
    func deleteFolder(id: UUID) async throws
}
