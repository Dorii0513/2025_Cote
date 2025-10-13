//
//  Task.swift
//  Cote
//
//  Created by 김예림 on 10/6/25.
//

import RealmSwift
import Foundation

final class TagObject: Object {
    @Persisted(primaryKey: true) var name: String   //중복 방지
    @Persisted(originProperty: "tags") var notes: LinkingObjects<NoteObject>
}

final class FolderObject: Object {
    @Persisted(primaryKey: true) var id: UUID
    @Persisted var name: String = ""
    @Persisted var sortIndex: Int = 0
    @Persisted var updatedAt: Date = .now
    @Persisted var notes = List<NoteObject>()
    @Persisted var children = List<FolderObject>()
    @Persisted(originProperty: "children") var parent: LinkingObjects<FolderObject>
    //LinkingObjects(fromType: FolderObject.self, property: "children")
}

final class NoteObject: Object {
    @Persisted(primaryKey: true) var id: UUID
    @Persisted var title: String
    @Persisted var content: String
    @Persisted var tags = List<TagObject>()
    @Persisted var sortIndex: Int = 0
    @Persisted var updatedAt: Date = .now
    @Persisted(originProperty: "notes") var parentFolders: LinkingObjects<FolderObject>
}

extension NoteObject {
    convenience init(from note: Note) {
        self.init()
        self.id = note.id
        self.title = note.title
        self.content = note.content
        
        let noteTags = List<TagObject>()
        for tag in note.tags {
            let obj = TagObject()
            obj.name = tag.name
            noteTags.append(obj)
        }
        self.tags = noteTags
        self.updatedAt = note.updatedAt
        // 필요하면 sortIndex도 note에서 받아서 설정
    }
    
    func toDomain() -> Note {
        let domainTags: [Tag] = tags.map { Tag(name: $0.name) }
        return Note(
            id: id,
            title: title,
            content: content,
            tags: domainTags,
            sortIndex: sortIndex,
            updatedAt: updatedAt
        )
    }
}

extension FolderObject {
    // Domain -> Realm
    convenience init(from folder: Folder) {
        self.init()
        self.id        = folder.id
        self.name      = folder.name
        self.sortIndex = folder.sortIndex
        self.updatedAt = folder.updatedAt

        // 자식 노트/폴더 주입 (깊은 변환)
        self.notes.removeAll()
        self.notes.append(objectsIn: folder.notes.map { NoteObject(from: $0) })

        self.children.removeAll()
        self.children.append(objectsIn: folder.children.map { FolderObject(from: $0) })
        // parent 는 LinkingObjects라 직접 설정하지 않음
    }

    // Realm -> Domain
    func toDomain() -> Folder {
        Folder(
            id: id,
            name: name,
            sortIndex: sortIndex,
            updatedAt: updatedAt,
            notes: notes.map { Note($0) },                 // NoteObject -> Note
            children: children.map { $0.toDomain() },      // 재귀 변환
        )
    }

    /// 기존 객체에 도메인 값을 덮어쓰고 싶을 때(업데이트용)
    func apply(from folder: Folder) {
        self.name      = folder.name
        self.sortIndex = folder.sortIndex
        self.updatedAt = folder.updatedAt

        self.notes.removeAll()
        self.notes.append(objectsIn: folder.notes.map { NoteObject(from: $0) })

        self.children.removeAll()
        self.children.append(objectsIn: folder.children.map { FolderObject(from: $0) })
    }
}


