//
//  Sidebar.swift
//  Cote
//
//  Created by 김예림 on 7/22/25.
//

import SwiftUI
import UniformTypeIdentifiers

//MARK: - Folder뷰

struct FolderView: View {
    @EnvironmentObject var state: UIState
    @StateObject private var viewModel = SideBarViewModel()
    
    // 버튼
    @State var addFolderSelected: Bool = false
    @State var addNoteSelected: Bool = false
    
    @State private var newNote: Note = .init(NoteObject.init())
    @State private var newFolder: Folder = .init(FolderObject.init())
    
    @FocusState var focusField: FocusTarget?
    @State private var hasLoaded = false    // cell
    @State private var expandedIDs = Set<UUID>()
    
    @State private var showFolderField = false
    @State private var showNoteField = false
    
    private var topMenuBar: some View {
        HStack(spacing: 2) {
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
                    selectedNoteID: state.selectedNoteID,
                    item: item,
                    depth: 0
                ) { id in
                    state.selectedNoteID = id
                    viewModel.select(id)
                    print("탭")
                    print(state.selectedNoteID ?? "nil")
                }
                // 위치 관련 수정 필요
                .contextMenu {
                    switch item {
                    case .note(let n):
                        Button(role: .destructive) {
                            viewModel.deleteNote(id: n.id)
                        } label: {
                            Label("노트 삭제하기", systemImage: "trash")
                        }
                        
                    case .folder(let f):
                        Button(role: .destructive) {
                            viewModel.deleteFolder(id: f.id)
                        } label: {
                            Label("폴더 삭제하기", systemImage: "trash")
                        }
                    }
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .leading).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
            }
        }
        .dropDestination(for: String.self) { items, _ in
            if let first = items.first, let noteID = UUID(uuidString: first) {
                // 바깥(루트)으로 이동
                viewModel.moveNoteToRoot(noteID: noteID)
                return true
            }
            return false
        } isTargeted: { _ in }
    }
    
    @ViewBuilder
    private var newFolderRow: some View {
        if showFolderField  {
            HStack(spacing: 0) {
                Image("arrow_right")
                    .foregroundStyle(.iconSecondary)
                TextField("", text: $newFolder.name)
                    .focused($focusField, equals: .addFolder)
                    .tint(.textDefault)
                    .coteFont(.text3, color: .textDefault)
                    .padding(.horizontal, 4)
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
                            .stroke(Color.borderDefault, lineWidth: focusField == .addFolder ? 2 : 1)
                    )
                    .onSubmit(of: .text) {
                        withAnimation(.easeInOut) {
                            if !newFolder.name.isEmpty {
                                viewModel.createFolder(name: newFolder.name)
                                newFolder.name = ""
                            }
                            focusField = nil
                        }
                    }
            }
            .padding([.horizontal, .vertical], 5)
        }
    }
    
    
    @ViewBuilder
    private var newNoteRow: some View {
        if showNoteField {
            HStack {
                Spacer().frame(width: 20)
                TextField("", text: $newNote.title)
                    .focused($focusField, equals: .addNote)
                    .tint(.textDefault)
                    .coteFont(.text3, color: .textDefault)
                    .padding(.horizontal, 4)
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
                            .stroke(Color.borderDefault, lineWidth: focusField == .addNote ? 2 : 1)
                    )
                    .onSubmit(of: .text) {
                        withAnimation(.easeInOut) {
                            if !newNote.title.isEmpty {
                                viewModel.createNote(note: newNote)
                                newNote.title = ""
                                state.selectedNoteID = newNote.id
                            }
                            focusField = nil
                        }
                    }
            }
            .padding(.top, 5)
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                topMenuBar
                rootsList
                newFolderRow
                newNoteRow
                Spacer()
            }
            .frame(maxWidth: .infinity)
            .onChange(of: addFolderSelected) { _, selected in
                if selected {
                    showFolderField = true
                    focusField = .addFolder
                    addFolderSelected = false
                }
            }
            .onChange(of: addNoteSelected) { _, selected in
                if selected {
                    showNoteField = true
                    focusField = .addNote
                    addNoteSelected = false
                }
            }
            .onChange(of: focusField) { oldValue, newValue in
                if oldValue == .addNote && newValue != .addNote && showNoteField && newNote.title.isEmpty {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        showNoteField = false
                    }
                }
                
                if oldValue == .addFolder && newValue != .addFolder && showFolderField && newFolder.name.isEmpty {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        showFolderField = false
                    }
                }
            }
            // focus 해제
            .contentShape(Rectangle())
            .onTapGesture {
                focusField = nil
            }
            .onChange(of: viewModel.roots.count) {
                if !hasLoaded { hasLoaded = true }
            }
        }
        .padding(.horizontal, 10)
        .padding(0)
        .onReceive(NotificationCenter.default.publisher(for: .moveNoteRequest)) { notification in
            if let userInfo = notification.userInfo,
               let n = userInfo["noteID"] as? UUID,
               let f = userInfo["folderID"] as? UUID {
                viewModel.moveNote(noteID: n, toFolder: f)
            }
        }
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

