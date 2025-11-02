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
    @Persisted var language: String = ""
    @Persisted var embedding: Data?
    @Persisted(originProperty: "notes") var parentFolders: LinkingObjects<FolderObject>
}

//MARK: - Extension
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
        self.language = note.language
        
        if let emb = note.embedding {
            self.embedding = EmbeddingCodec.encode(emb)
        } else {
            self.embedding = nil
        }
    }
    
    func toDomain() -> Note {
        let domainTags: [Tag] = tags.map { Tag(name: $0.name) }
        let embedding = embedding.map { EmbeddingCodec.decode($0) }
        return Note(
            id: id,
            title: title,
            content: content,
            tags: domainTags,
            sortIndex: sortIndex,
            updatedAt: updatedAt,
            language: language,
            embedding: embedding
        )
    }
}

extension FolderObject {
    convenience init(from folder: Folder) {
        self.init()
        self.id        = folder.id
        self.name      = folder.name
        self.sortIndex = folder.sortIndex
        self.updatedAt = folder.updatedAt

        self.notes.removeAll()
        self.notes.append(objectsIn: folder.notes.map { NoteObject(from: $0) })

        self.children.removeAll()
        self.children.append(objectsIn: folder.children.map { FolderObject(from: $0) })
    }

    // Realm -> Domain
    func toDomain() -> Folder {
        Folder(
            id: id,
            name: name,
            sortIndex: sortIndex,
            updatedAt: updatedAt,
            notes: notes.map { Note($0) },
            children: children.map { $0.toDomain() },
        )
    }

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
