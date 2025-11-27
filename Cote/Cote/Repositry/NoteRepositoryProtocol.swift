//
//  NoteRepository.swift
//  Cote
//
//  Created by 김예림 on 10/6/25.
//

import Foundation

protocol NoteRepositoryProtocol {
    func itemStream() -> AsyncStream<[NoteItems]>
    func noteStream(id: UUID) -> AsyncStream<Note?>
    
    func updateNoteTitle(id: UUID, title: String) async throws
    func updateNoteContent(id: UUID, content: String) async throws
    func updateNoteEmbadding(id: UUID, embadding: Data) async throws
    func updateNoteTags(id: UUID, tags: [Tag]) async throws
    func updateNoteLanguage(id: UUID, language: String) async throws
    func deleteNote(id: UUID) async throws
    func createNote(note: Note) async throws
    func fetchNote(by id: UUID) async throws -> Note?
    func moveNote(noteID: UUID, toFolderID: UUID) async throws
    func moveNoteToRoot(noteID: UUID) async throws
    
    func createFolder(name: String, parentID: UUID?) async throws -> UUID
    func deleteFolder(id: UUID) async throws
    func updateFolderName(id: UUID, name: String) async throws
    
    func deleteTag(noteID: UUID, tagName: String) async throws
    
    func fetchNoteLight(limit: Int?) async throws -> [(UUID, String, String, [String], Date, [String], [Float]?)]
}
