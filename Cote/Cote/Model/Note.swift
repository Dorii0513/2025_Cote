//
//  Note.swift
//  Cote
//
//  Created by 김예림 on 7/25/25.
//

import Foundation

struct Folder: Identifiable {
    let id = UUID()
    var name: String
    var notes: [Note] = []
    var folders: [Folder] = []
}

struct Note: Identifiable {
    let id = UUID()
    var title: String
    var content: String
}

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
            let folders = f.folders.map(NoteItems.folder)
            let notes   = f.notes.map(NoteItems.note)
            return folders + notes
        case .note:
            return []
        }
    }
}
