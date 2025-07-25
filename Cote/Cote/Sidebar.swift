//
//  Sidebar.swift
//  Cote
//
//  Created by 김예림 on 7/22/25.
//

import SwiftUI

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

// 2) 트리 구조 표현용 enum
enum NoteItems: Identifiable {
    case folder(Folder)
    case note(Note)
    
    var id: UUID {
        switch self {
        case .folder(let f): return f.id
        case .note(let n):   return n.id
        }
    }
    
    // OutlineGroup 등이 읽어갈 children 프로퍼티
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

struct Sidebar: View {
    @State var isTapped: Bool = false
    @State private var expandedIDs = Set<UUID>()
    let roots: [NoteItems] = [
        .folder(Folder(name: "문서", notes: [Note(title: "메모", content: "앱 아이디어")], folders: [Folder(name: "프로젝트", notes: [], folders: [])])),
        .note(Note(title: "할 일", content: "SwiftUI 공부")),
        .folder(Folder(name: "프로젝트", notes: [], folders: [])),
        .note(Note(title: "메모", content: "앱 아이디어")),
        .note(Note(title: "영화 목록", content: "..."))
    ]
    
    var body: some View {
        
        ZStack {
            
            Color.bgSurfaceSidebar
                .blur(radius: 100)
            
            VStack {
                HStack {
                    
                    MenuButton(name: "addFolder", action: {isTapped.toggle()})
                    
                    MenuButton(name: "addNote", action: {isTapped.toggle()})
                    
                    Spacer()
                    
                    MenuButton(name: "filter", action: {isTapped.toggle()})
                }
                .padding(.horizontal, 15)
                .padding(.vertical, 5)
                
                Spacer()
                    .frame(height:5)
                
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(roots) { item in
                        ListCell(expandedIDs: $expandedIDs, item: item, depth: 0)
                    }
                }
                .padding(.horizontal, 10)
                
                Spacer()
            }
        }
        .padding(0)
        .frame(width: 270, height: 970)
    }
}

#Preview {
    Sidebar()
}
