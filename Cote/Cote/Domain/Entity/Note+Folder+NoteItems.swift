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
    
    init(id: UUID, name: String, sortIndex: Int, updatedAt: Date, notes: [Note], children: [Folder], parentID: UUID? = nil) {
        self.id = id
        self.name = name
        self.sortIndex = sortIndex
        self.updatedAt = updatedAt
        self.notes = notes
        self.children = children
        self.parentID = parentID
    }
}

struct Note: Identifiable {
    let id: UUID
    var title: String
    var content: String
    var tags: [Tag] = []
    var sortIndex: Int = 0
    var updatedAt: Date = .now
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
                return a.updatedAt > b.updatedAt
            case (.note(let a), .note(let b)):
                if a.sortIndex != b.sortIndex { return a.sortIndex < b.sortIndex }
                return a.updatedAt > b.updatedAt
            case (.folder, .note): return true    // 폴더가 노트보다 앞
            case (.note, .folder): return false
            }
        }
    }
}
