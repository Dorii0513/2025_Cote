//
//  Sidebar.swift
//  Cote
//
//  Created by 김예림 on 7/22/25.
//

import SwiftUI

//MARK: - Folder뷰

struct FolderView: View {
    @EnvironmentObject var state: UIState
    @StateObject private var viewModel = SideBarViewModel()
    
    @State var addFolderSelected: Bool = false
    @State var addNoteSelected: Bool = false
    @State var filterSelected: Bool = false
    
    @State private var expandedIDs = Set<UUID>()
    
    var body: some View {
        ScrollView {
            VStack {
                HStack(spacing: 4) {
                    
                    MenuButton(selected: $addFolderSelected,
                               icon: CoteIcon.addFolder)
                    
                    MenuButton(selected: $addFolderSelected,
                               icon: CoteIcon.addNote)
                    
                    Spacer()
                    
                    MenuButton(selected: $addFolderSelected,
                               icon: CoteIcon.filter)
                }
                .padding(.vertical, 4)
                
                Spacer()
                    .frame(height:5)
                
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(viewModel.roots) { item in
                        ListCell(expandedIDs: $expandedIDs,
                                 noteID: state.selectedNoteID, // 선택된 노트 전달
                                 onSelect: { id in state.selectedNoteID = id }, // 선택한 노트 업데이트
                                 item: item,
                                 depth: 0)
                    }
                }
                
                Spacer()
            }
        }
        .padding(.horizontal, 10)
        .padding(0)
        .onAppear {
            viewModel.attach(state)
        }
    }
}


//#Preview {
//    FolderView()
//}
