//
//  Note+Folder.swift
//  Cote
//
//  Created by 김예림 on 7/25/25.
//

import Foundation

struct Folder: Identifiable {
    let id: UUID
    var parentID: UUID? = nil
    var name: String
    var sortIndex: Int = 0
    var updatedAt: Date = .now
    var notes: [Note] = []
    var children: [Folder] = []
}

extension Folder {
    init(_ o: FolderObject) {
        self.init(
            id: o.id,
            name: o.name,
            sortIndex: o.sortIndex,
            updatedAt: o.updatedAt,
            notes: o.notes.map(Note.init(_:)),
            children: o.children.map(Folder.init(_:)),
        )
    }
}

struct Note: Identifiable {
    let id: UUID
    var title: String
    var content: String
    var tags: [Tag] = []
    var sortIndex: Int = 0
    var updatedAt: Date = .now
    
    init(id: UUID, title: String, content: String, tags: [Tag], sortIndex: Int, updatedAt: Date) {
        self.id = id
        self.title = title
        self.content = content
        self.tags = tags
        self.sortIndex = sortIndex
        self.updatedAt = updatedAt
    }
}

// UI용
enum NoteItems: Identifiable {
    case folder(Folder)
    case note(Note)
    
    var id: UUID {
        switch self {
        case .folder(let f): return f.id
        case .note(let n):   return n.id
        }
    }
    
    var children: [NoteItems] {
        switch self {
        case .folder(let f):
            let folders = f.children.map(NoteItems.folder)
            let notes   = f.notes.map(NoteItems.note)
            return folders + notes
        case .note:
            return []
        }
    }
    
    var childrenSorted: [NoteItems] { children.sortNotes() }
}

// 정렬 규칙
extension Array where Element == NoteItems {
    func sortNotes() -> [NoteItems] {
        self.sorted {
            switch ($0, $1) {
            case (.folder(let a), .folder(let b)):
                if a.sortIndex != b.sortIndex { return a.sortIndex < b.sortIndex }
                return a.updatedAt < b.updatedAt    // 최신이 아래로
            case (.note(let a), .note(let b)):
                if a.sortIndex != b.sortIndex { return a.sortIndex < b.sortIndex }
                return a.updatedAt < b.updatedAt
            case (.folder, .note): return true    // 폴더가 노트보다 앞
            case (.note, .folder): return false
            }
        }
    }
}
