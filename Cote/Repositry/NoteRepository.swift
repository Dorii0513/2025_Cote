//
//  NoteRepository.swift
//  Cote
//
//  Created by 김예림 on 10/6/25.
//

import Foundation

protocol NoteRepository {
    func treeStream() -> AsyncStream<[Folder]>
    func noteStream(id: UUID) -> AsyncStream<Note?>
    func save(note: Note) async throws
    func create(note: Note) throws -> Note
//    func notes(in folderID: String?) throws -> [Note]
//    func nextSortIndex(for folderID: String?) throws -> Int
    func fetchAllSortedByDateDesc() async throws -> [Note]
    func delete(id: UUID) async throws
}
