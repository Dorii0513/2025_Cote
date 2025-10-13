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
    
    // 버튼
    @State var addFolderSelected: Bool = false
    @State var addNoteSelected: Bool = false
    
    // 노트
    @State private var newNote: Note = .init(NoteObject.init())
    
    @FocusState private var isFocused: Bool
    @State private var hasLoaded = false    // cell
    @State private var expandedIDs = Set<UUID>()
    
    private func focousChanged() {
        if addNoteSelected {
            isFocused = true
        }
    }
    
    private var topMenuBar: some View {
        HStack(spacing: 4) {
            MenuButton(selected: $addFolderSelected, icon: CoteIcon.addFolder)
            MenuButton(selected: $addNoteSelected, icon: CoteIcon.addNote)
            Spacer()
            MenuButton(selected: $addFolderSelected, icon: CoteIcon.filter)
        }
        .padding(.vertical, 4)
    }
    
    private var rootsList: some View {
        VStack(alignment: .leading, spacing: 2) {
            ForEach(viewModel.roots) { item in
                ListCell(
                    expandedIDs: $expandedIDs,
                    noteID: state.selectedNoteID,
                    item: item,
                    depth: 0
                ) { id in
                    state.selectedNoteID = id
                    viewModel.select(id)
                    print("탭")
                    print(state.selectedNoteID ?? "nil")
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .leading).combined(with: .opacity),
                    removal: .move(edge: .trailing).combined(with: .opacity)
                ))
            }
            .animation(hasLoaded ? .smooth(duration: 0.5) : nil, value: viewModel.roots.count)
        }
    }
    
    @ViewBuilder
    private var newNoteRow: some View {
        if state.addNewNote {
            HStack {
                Spacer().frame(width: 20)
                TextField("", text: $newNote.title)
                    .focused($isFocused)
                    .tint(.textDefault)
                    .coteFont(.title2, color: .textDefault)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 5)
                    .frame(height: 20)
                    .frame(minWidth: 60, alignment: .leading)
                    .fixedSize()
                    .textFieldStyle(.plain)
                    .background(
                        GeometryReader { proxy in
                            Color.clear
                                .anchorPreference(key: TitleFieldAnchorKey.self, value: .bounds) { $0 }
                        }
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(Color.border, lineWidth: isFocused ? 2 : 1)
                    )
                    .onSubmit(of: .text) {
                        withAnimation(.smooth) {
                            viewModel.addNewNote(note: newNote)
                            newNote.title = ""
                            state.addNewNote = false
                        }
                    }
                    .onChange(of: isFocused, initial: false) { _, newValue in
                        if !newValue && newNote.title.isEmpty {
                            withAnimation(.snappy) {
                                state.addNewNote = false
                            }
                        }
                    }
            }
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                topMenuBar
                Spacer().frame(height: 5)
                rootsList
                newNoteRow
                Spacer()
            }
            .onChange(of: addNoteSelected) {
                focousChanged()
            }
            .onChange(of: viewModel.roots.count) {
                if !hasLoaded { hasLoaded = true }
            }
        }
        .padding(.horizontal, 10)
        .padding(0)
    }
}


private struct TitleFieldAnchorKey: PreferenceKey {
    static var defaultValue: Anchor<CGRect>? = nil
    static func reduce(value: inout Anchor<CGRect>?, nextValue: () -> Anchor<CGRect>?) {
        value = nextValue() ?? value
    }
}

//#Preview {
//    FolderView()
//}

