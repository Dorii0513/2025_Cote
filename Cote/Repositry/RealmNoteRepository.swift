//
//  RealmNoteRepository.swift
//  Cote
//
//  Created by 김예림 on 10/6/25.
//

import Foundation
import RealmSwift

@MainActor
struct RealmNoteRepository: NoteRepository {
    
    private func openRealm() throws -> Realm { try Realm() }
    
    func itemStream() -> AsyncStream<[NoteItems]> {
        AsyncStream { continuation in
            do {
                let realm = try openRealm()
                let folders = realm.objects(FolderObject.self)
                let notes   = realm.objects(NoteObject.self)
                
                func emit() {
                    
                    // 1) 루트 폴더(부모 없음)
                    let rootFolders = realm.objects(FolderObject.self)
                        .filter("parent.@count == 0")
                        .sorted(byKeyPath: "sortIndex", ascending: true)
                        .map { FolderMapper.folder(from: $0) }
                        .map(NoteItems.folder)
                    
                    // 2) 루트 노트(어떤 폴더에도 속하지 않음)
                    let rootNotes = realm.objects(NoteObject.self)
                        .where { $0.parentFolders.count == 0 }
                        .sorted(byKeyPath: "sortIndex", ascending: true)
                        .map { Note($0) }
                        .map(NoteItems.note)
                    
                    // 3) 합치고 정렬 규칙 적용
                    let merged = Array(rootFolders) + Array(rootNotes)
                    continuation.yield(merged.sortNotes())
                }
                
                emit() // 초기 1회
                
                let t1 = folders.observe { _ in emit() }
                let t2 = notes.observe   { _ in emit() }
                
                continuation.onTermination = { _ in
                    t1.invalidate(); t2.invalidate()
                }
            } catch {
                continuation.finish()
            }
        }
    }
    
    // 노트의 최신 상태를 업데이트
    func noteStream(id: UUID) -> AsyncStream<Note?> {
        AsyncStream { continuation in
            do {
                let realm = try openRealm()
                // PK 타입은 UUID 그대로 사용 (uuidString 아님)
                let result = realm.objects(NoteObject.self).where { $0.id == id }
                
                print("[Repo.noteStream] subscribe id=", id)
                
                func emit() {
                    if let obj = result.first { continuation.yield(obj.toDomain()) }
                    else { continuation.yield(nil) }
                }
                
                emit()
                let token = result.observe { _ in emit() }
                continuation.onTermination = { _ in token.invalidate() }
            } catch {
                continuation.finish()
            }
        }
    }
    
    
    func create(note: Note) async throws {
        let realm = try await Realm()
        try realm.write {
            let obj = NoteObject(from: note)
            realm.add(obj, update: .modified)
        }
    }
    
    func save(note: Note) async throws {
        let realm = try openRealm()
        try await realm.asyncWrite {
            let obj = NoteObject(from: note)
            realm.add(obj, update: .modified)
        }
    }
    
    func fetchAllSortedByDateDesc() async throws -> [Note] {
        let realm = try openRealm()
        let results = realm.objects(NoteObject.self)
            .sorted(byKeyPath: "updatedAt", ascending: false)
        return results.map { $0.toDomain() }
    }
    
    // 선택한 노트 fetch
    func fetchNote(by id: UUID) async throws -> Note? {
        let realm = try openRealm()
        return realm.object(ofType: NoteObject.self, forPrimaryKey: id)?.toDomain()
    }
    
    func delete(id: UUID) async throws {
        let realm = try openRealm()
        if let obj = realm.object(ofType: NoteObject.self, forPrimaryKey: id) {
            try await realm.asyncWrite {
                realm.delete(obj)
            }
        }
    }
}

enum FolderMapper {
    static func folder(from o: FolderObject) -> Folder {
        let notes: [Note] = o.notes
            .sorted(byKeyPath: "sortIndex", ascending: true)
            .map(Note.init)
        
        let children: [Folder] = o.children
            .sorted(byKeyPath: "sortIndex", ascending: true)
            .map(FolderMapper.folder(from:))
        
        // Domain Folder가 id 주입 생성자를 가지도록(권고된 수정안)
        return Folder(
            id: o.id,
            name: o.name,
            sortIndex: o.sortIndex,
            updatedAt: o.updatedAt,
            notes: notes,
            children: children,
            parentID: o.parent.first?.id
        )
    }
}
extension Note {
    init(_ o: NoteObject) {
        self.init(id: o.id,
                  title: o.title,
                  content: o.content,
                  tags: o.tags.map { Tag(name: $0.name) },
                  sortIndex: o.sortIndex,
                  updatedAt: o.updatedAt)
    }
}
