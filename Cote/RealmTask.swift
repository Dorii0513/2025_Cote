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

