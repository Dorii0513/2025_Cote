//
//  Task.swift
//  Cote
//
//  Created by 김예림 on 10/6/25.
//

import RealmSwift
import Foundation

final class TagObject: Object {
    @Persisted(primaryKey: true) var id: ObjectId = .generate()
    @Persisted var name: String
    //@Persisted(originProperty: "tags") var notes: LinkingObjects<NoteObject> // 노트 역참조
}

final class NoteObject: Object {
    @Persisted(primaryKey: true) var id: UUID
    @Persisted var date: Date
    @Persisted var title: String
    @Persisted var content: String
    @Persisted var tags: List<TagObject>
}

extension NoteObject {
    convenience init(from note: Note) {
        self.init()
        self.id = note.id
        self.date = note.date
        self.title = note.title
        self.content = note.content
        
        let noteTags = List<TagObject>()
        for tag in note.tags {
            let obj = TagObject()
            obj.name = tag.name
            noteTags.append(obj)
        }
        self.tags = noteTags
    }

    func toDomain() -> Note {
        let domainTags: [Tag] = tags.map { Tag(name: $0.name) }
        return Note(
            id: id,
            date: date,
            title: title,
            content: content,
            tags: domainTags
        )
    }
}
