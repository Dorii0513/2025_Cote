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
    
    @State private var newNoteTitle: String = ""
    @State private var newFolderName: String = ""
    
    @State private var renamingFolderID: UUID? = nil
    @State private var renamingFolderName: String = ""
    @State private var isFolderRenaming = false
    
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
                ListCell(expandedIDs: $expandedIDs,
                         renamingFolderID: $renamingFolderID,
                         renamingName: $renamingFolderName,
                         selectedNoteID: state.selectedNoteID,
                         item: item,
                         depth: 0,
                         onSelect: { id in
                    state.previousNoteID = state.selectedNoteID
                    state.selectedNoteID = id
                    viewModel.select(id)
                }, onCommitRename: { id, name in
                    Task {
                        await viewModel.updateFolderName(id: id, newName: name)
                    }
                }, onDeleteNote: { id in
                    viewModel.deleteNote(id: id)
                }, onStartRename: { id, name in
                    withAnimation(.easeIn(duration: 0.3)) {
                        renamingFolderID = id
                        renamingFolderName = name
                    }
                }, onDeleteFolder: { id in
                    Task {
                        await viewModel.deleteFolder(id: id)
                    }
                })
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
            TextField("", text: $newFolderName)
                .focused($focusField, equals: .addFolder)
                .tint(.actionFocus)
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
                .transition(.move(edge: .top))
                .onSubmit(of: .text) {
                    withAnimation(.easeIn(duration: 0.4)) {
                        if !newFolderName.isEmpty {
                            viewModel.createFolder(name: newFolderName)
                            newFolderName = ""
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
            TextField("", text: $newNoteTitle)
                .focused($focusField, equals: .addNote)
                .tint(.actionFocus)
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
                    withAnimation(.easeIn(duration: 0.4)) {
                        if !newNoteTitle.isEmpty {
                            Task {
                                await viewModel.createNote(title: newNoteTitle)
                                newNoteTitle = ""
                                await MainActor.run {
                                    state.selectedNoteID = viewModel.selectedNoteID
                                }
                                focusField = nil
                            }
                        }
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
        .onChange(of: focusField) { _, newValue in
            if newValue != .addNote && showNoteField && newNoteTitle.isEmpty {
                withAnimation(.easeInOut(duration: 0.15)) {
                    showNoteField = false
                }
            }
            
            if newValue != .addFolder && showFolderField && newFolderName.isEmpty {
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

