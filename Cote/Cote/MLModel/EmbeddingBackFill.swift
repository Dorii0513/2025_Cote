//
//  EmbeddingBackFill.swift
//  Cote
//
//  Created by 김예림 on 11/2/25.
//

import Foundation
import RealmSwift

// 이미 생성된 노트에 embedding 추가
struct EmbeddingBackFill {
        private let embed = E5EmbeddingModel()

        @MainActor
        func run() async {
            do {
                let realm = try await Realm()
                
                // 아직 embedding이 비어있는 노트만
                let objs = realm.objects(NoteObject.self).where { $0.embedding == nil }
                guard !objs.isEmpty else {
                    print("✅ 모든 노트가 이미 임베딩을 가지고 있음.")
                    return
                }

                print(" 임베딩 없는 노트 수: \(objs.count)")
                try realm.write {
                    for obj in objs {
                        let text = "passage: \(obj.content)"
                        if let vec = try? embed.embedding(for: text) {
                            obj.embedding = EmbeddingCodec.encode(vec.map { Float($0) })
                        }
                    }
                }

                print("✅ Backfill 완료: \(objs.count)개 노트 처리됨.")
            } catch {
                print("❌ Backfill 실패:", error)
            }
        }
}
