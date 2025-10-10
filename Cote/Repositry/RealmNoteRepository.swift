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
    
    //    private let realm: Realm
    
    private func openRealm() throws -> Realm { try Realm() }
    
    
    func treeStream() -> AsyncStream<[Folder]> {
        AsyncStream { continuation in
            do {
                let realm = try openRealm()
                let folders = realm.objects(FolderObject.self)
                let notes   = realm.objects(NoteObject.self)
                
                func emit() {
                    // RealmObject → Folder(네가 가진 struct)로 변환
                    let roots: [Folder] = FolderMapper.fromRealmTree(realm)
                    continuation.yield(roots)
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
                let realm = try Realm()
                let result = realm.objects(NoteObject.self) //받아온 id 랑 일치하는 note 찾기
//                    .where { $0.id == id.uuidString }
                
                func emit() {
                    if let first = result.first {
                        continuation.yield(first.toDomain())
                    } else {
                        continuation.yield(nil)
                    }
                }
                emit()
                
                let token = result.observe { _ in emit() }
                continuation.onTermination = { _ in token.invalidate() }
            } catch {
                continuation.finish()
            }
        }
    }
    
    func create(note: Note) throws -> Note {
        let obj = NoteObject(from: note)
        let realm = try Realm()
        let reslut: () = try realm.write(){
            realm.add(obj)
        }
        return obj.toDomain()
    }
    
    //    func notes(in folderID: String?) throws -> [Note] {
    //        // 폴더별로 관리한다면 FolderObject.notes를 통해 가져오도록 구현
    //        // 우선 단순 전역 정렬 예시:
    //        let results = realm.objects(NoteObject.self).sorted(byKeyPath: "sortIndex")
    //        return results.map { $0.toDomain() }
    //    }
    //
    //    func nextSortIndex(for folderID: String?) throws -> Int {
    //        // 폴더별 정렬이라면 해당 폴더의 notes.max(ofProperty:) 등으로 계산
    //        let maxIndex = realm.objects(NoteObject.self).max(ofProperty: "sortIndex") as Int? ?? -1
    //        return maxIndex + 1
    //    }
    
    func save(note: Note) async throws {
        let realm = try await openRealm()
        try await realm.asyncWrite {
            let obj = NoteObject(from: note)
            realm.add(obj, update: .modified)
        }
    }
    
        func fetchAllSortedByDateDesc() async throws -> [Note] {
            let realm = try await openRealm()
            let results = realm.objects(NoteObject.self)
                .sorted(byKeyPath: "updatedAt", ascending: false)
            return results.map { $0.toDomain() }
        }
    
    func delete(id: UUID) async throws {
        let realm = try await openRealm()
        if let obj = realm.object(ofType: NoteObject.self, forPrimaryKey: id) {
            try await realm.asyncWrite {
                realm.delete(obj)
            }
        }
    }
}

enum FolderMapper {
    static func fromRealmTree(_ realm: Realm) -> [Folder] {
        let roots = realm.objects(FolderObject.self)
            .filter("parent.@count == 0")
            .sorted(byKeyPath: "sortIndex", ascending: true)
        return roots.map(folder(from:))
    }

    private static func folder(from o: FolderObject) -> Folder {
        let notes: [Note] = o.notes
            .sorted(byKeyPath: "sortIndex", ascending: true)
            .map(Note.init) // NoteObject -> Note (아래 확장)

        let children: [Folder] = o.children
            .sorted(byKeyPath: "sortIndex", ascending: true)
            .map(folder(from:))

        var f = Folder(name: o.name,
                       sortIndex: o.sortIndex,
                       updatedAt: o.updatedAt,
                       notes: notes,
                       children: children)
//        f.parentID = o.parent.first?.id.flatMap(UUID.init(uuidString:))
        return f
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
