//
//  Sidebar.swift
//  Cote
//
//  Created by 김예림 on 7/22/25.
//

import SwiftUI

struct Sidebar: View {
    var body: some View {
        ZStack {
            VStack(spacing: 4) {
                Rectangle()
                    .frame(height: 1)
                    .foregroundStyle(.actionDefault)
                FolderView()
            }
        }
        .frame(minWidth: 210, minHeight: 700)
        .background(Color.clear)
    }
}


//MARK: - Folder뷰

private struct FolderView: View {
    @State var addFolderSelected: Bool = false
    @State var addNoteSelected: Bool = false
    @State var filterSelected: Bool = false
    
    @State private var expandedIDs = Set<UUID>()
    
    // dummy
    let roots: [NoteItems] = [
        .folder(Folder(name: "Untitled1", notes: [Note(title: "Untitled2", content: "앱 아이디어")], folders: [Folder(name: "Untitled3", notes: [], folders: [])])),
        .note(Note(title: "Untitled4", content: "SwiftUI 공부")),
        .folder(Folder(name: "Untitled5", notes: [], folders: [])),
        .note(Note(title: "Untitled6", content: "앱 아이디어")),
        .note(Note(title: "Untitled7", content: "..."))
    ]
    
    var body: some View {
        ScrollView {
            VStack {
                HStack(spacing: 4) {
                    
                    MenuButton(selected: $addFolderSelected,
                               icon: CoteIcon.addFolder,
                               action: {})
                    
                    MenuButton(selected: $addFolderSelected,
                               icon: CoteIcon.addNote,
                               action: {})
                    
                    Spacer()
                    
                    MenuButton(selected: $addFolderSelected,
                               icon: CoteIcon.filter,
                               action: {})
                }
                .padding(.vertical, 4)
                
                Spacer()
                    .frame(height:5)
                
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(roots) { item in
                        ListCell(expandedIDs: $expandedIDs, item: item, depth: 0)
                    }
                }
                
                Spacer()
            }
        }
        .padding(.horizontal, 10)
        .padding(0)
    }
}


#Preview {
    Sidebar()
}
