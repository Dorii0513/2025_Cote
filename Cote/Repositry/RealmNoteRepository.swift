//
//  RealmNoteRepository.swift
//  Cote
//
//  Created by 김예림 on 10/6/25.
//

import Foundation
import RealmSwift

@MainActor
struct RealmNoteRepository: @preconcurrency NoteRepository {
    
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
    
    
    //MARK: - Note
    func createNote(note: Note) async throws {
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
    
    //MARK: - Folder
    func createFolder(name: String, parentID: UUID?) async throws -> UUID {
        let realm = try openRealm()
        let id = UUID()

        try await realm.asyncWrite {
            let folder = FolderObject()
            folder.id = id
            folder.name = name
            folder.updatedAt = Date()

            if let pid = parentID, let parent = realm.object(ofType: FolderObject.self, forPrimaryKey: pid) {
                // 부모가 있는 경우
                let maxIndex = parent.children.max(ofProperty: "sortIndex") as Int? ?? -1
                folder.sortIndex = maxIndex + 1

                parent.children.append(folder)
                parent.updatedAt = Date()
                realm.add(folder)                   // 새 폴더만 add
            } else {
                // 루트 폴더
                let rootFolders = realm.objects(FolderObject.self).where { $0.parent.count == 0 }
                let maxIndex = rootFolders.max(ofProperty: "sortIndex") as Int? ?? -1
                folder.sortIndex = maxIndex + 1

                realm.add(folder)
            }
        }
        return id
    }
    
    // MARK: - Drag & Drop
    func moveNote(noteID: UUID, toFolderID folderID: UUID) async throws {
        let realm = try openRealm()
        guard let note = realm.object(ofType: NoteObject.self, forPrimaryKey: noteID),
              let folder = realm.object(ofType: FolderObject.self, forPrimaryKey: folderID) else {
            throw CocoaError(.fileNoSuchFile)
        }
        
        try await realm.asyncWrite {
            if folder.notes.contains(where: { $0.id == noteID }) {
                return
            }
            
            for parent in note.parentFolders {
                if let idx = parent.notes.firstIndex(of: note) {
                    parent.notes.remove(at: idx)
                }
            }
            
            let maxIndex = folder.notes.max(ofProperty: "sortIndex") as Int? ?? -1
            note.sortIndex = maxIndex + 1
            
            folder.notes.append(note)
            folder.updatedAt = Date()
            note.updatedAt = Date()
        }
    }
    
    // MARK: - Root Move
    func moveNoteToRoot(noteID: UUID) async throws {
        let realm = try openRealm()
        guard let note = realm.object(ofType: NoteObject.self, forPrimaryKey: noteID) else {
            throw CocoaError(.fileNoSuchFile)
        }
        try await realm.asyncWrite {
            for parent in note.parentFolders {
                if let idx = parent.notes.firstIndex(of: note) {
                    parent.notes.remove(at: idx)
                    parent.updatedAt = Date()
                }
            }
            let rootNotes = realm.objects(NoteObject.self).where { $0.parentFolders.count == 0 }
            let maxIndex = rootNotes.max(ofProperty: "sortIndex") as Int? ?? -1
            note.sortIndex = maxIndex + 1
            note.updatedAt = Date()
        }
    }
    
    // MARK: - Folder Delete
    func deleteFolder(id folderID: UUID) async throws {
        let realm = try openRealm()
        guard let folder = realm.object(ofType: FolderObject.self, forPrimaryKey: folderID) else {
            throw CocoaError(.fileNoSuchFile)
        }
        try await realm.asyncWrite {
            self.recursiveDelete(folder: folder, in: realm)
        }
    }
    
    private func recursiveDelete(folder: FolderObject, in realm: Realm) {
        // 1) 하위 폴더 재귀 삭제
        for child in folder.children {
            recursiveDelete(folder: child, in: realm)
        }
        // 2) 폴더가 보유한 노트들을 전부 삭제
        for note in folder.notes {
            realm.delete(note)
        }
        // 3) 자신 삭제
        realm.delete(folder)
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
        
        return Folder(
            id: o.id,
            name: o.name,
            sortIndex: o.sortIndex,
            updatedAt: o.updatedAt,
            notes: notes,
            children: children,
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
                  updatedAt: o.updatedAt,
                  language: o.language)
    }
}

