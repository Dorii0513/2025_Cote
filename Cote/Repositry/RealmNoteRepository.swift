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

    private func openRealm() async throws -> Realm {
        // 최신 Realm은 async 초기화를 지원합니다.
        // MainActor에서 호출 중이면 try Realm()도 가능하지만,
        // async API를 추천합니다.
        try await Realm(configuration: .defaultConfiguration, actor: MainActor.shared)
    }

    func save(note: Note) async throws {
        let realm = try await openRealm()
        try await realm.asyncWrite {
            let obj = NoteObject(from: note)
            realm.add(obj, update: .modified) // 동일 id 있으면 업데이트
        }
    }

    func fetchAllSortedByDateDesc() async throws -> [Note] {
        let realm = try await openRealm()
        let results = realm.objects(NoteObject.self)
            .sorted(byKeyPath: "date", ascending: false)
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

