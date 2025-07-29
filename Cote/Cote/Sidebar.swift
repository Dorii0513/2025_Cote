//
//  Sidebar.swift
//  Cote
//
//  Created by 김예림 on 7/22/25.
//

import SwiftUI

struct Sidebar: View {
    @State var isTapped: Bool = false
    @State private var expandedIDs = Set<UUID>()
    
    // dummy
    let roots: [NoteItems] = [
        .folder(Folder(name: "문서", notes: [Note(title: "메모", content: "앱 아이디어")], folders: [Folder(name: "프로젝트", notes: [], folders: [])])),
        .note(Note(title: "할 일", content: "SwiftUI 공부")),
        .folder(Folder(name: "프로젝트", notes: [], folders: [])),
        .note(Note(title: "메모", content: "앱 아이디어")),
        .note(Note(title: "영화 목록", content: "..."))
    ]
    
    var body: some View {
        ZStack {
            BlurEffect()
            
            Color.bgSurfaceSidebar
            
            ScrollView {
                VStack {
                    HStack(spacing: 0) {
                        
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
        }
        .frame(minWidth: 210, minHeight: 750)
        .background(Color.clear)
    }
}

#Preview {
    Sidebar()
}
