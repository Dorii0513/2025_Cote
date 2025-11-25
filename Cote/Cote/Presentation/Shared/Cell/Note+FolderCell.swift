//
//  noteCell.swift
//  Cote
//
//  Created by 김예림 on 7/23/25.
//

import SwiftUI

struct ListCell: View {
    @State var isHover = false
    @FocusState var focusField: FocusTarget?
    
    @Binding var expandedIDs: Set<UUID>
    @Binding var renamingFolderID: UUID?
    @Binding var renamingName: String
    
    let selectedNoteID: UUID?
    let item: NoteItems
    let depth: Int
    
    let onSelect: (UUID) -> Void
    let onCommitRename: (UUID, String) -> Void
    
    // expandedIDs 값이 존재할 때 true
    private var isExpanded: Bool {
        switch item {
        case .folder(let f): return expandedIDs.contains(f.id)
        case .note: return false
        }
    }
    
    private var isSelected: Bool {
        switch item {
        case .folder: return false
        case .note(let n): return selectedNoteID == n.id
        }
    }
    
    private var isRenamingFolder: Bool {
        guard case .folder(let f) = item else { return false }
        return renamingFolderID == f.id
    }
    
    var body: some View {
        HStack(spacing: 0) {
            Spacer()
                .frame(width: 10 * CGFloat(depth))
            
            switch item {
            case.folder(let f):
                
                if isRenamingFolder {
                    HStack(spacing: 0) {
                        Image(isExpanded ? "arrow_down" : "arrow_right")
                            .foregroundStyle(.iconSecondary)
                        
                        TextField("", text: $renamingName)
                            .coteFont(.text3, color: .textSelected)
                            .tint(.actionFocus)
                            .focused($focusField, equals: .folder)
                            .textFieldStyle(.plain)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 5)
                            .background(
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(.bgTextField)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 4)
                                            .stroke(.borderDefault, lineWidth: 2)
                                    )
                            )
                            .onSubmit {
                                let name = renamingName.trimmingCharacters(in: .whitespacesAndNewlines)
                                if !name.isEmpty {
                                    onCommitRename(f.id, name)
                                }
                                withAnimation(.easeIn(duration: 0.3)) {
                                    renamingFolderID = nil
                                    focusField = nil
                                }
                            }
                            .onChange(of: focusField, {
                                if focusField == nil && renamingName == f.name {
                                    withAnimation(.easeIn(duration: 0.3)) {
                                        renamingFolderID = nil
                                    }
                                }
                            })
                    }
                } else {
                    Button {
                        toggleExpansion()
                    } label: {
                        FolderCell(isExpanded: isExpanded, folder: f, isHover: $isHover)
                    }
                    .buttonStyle(.plain)
                    .dropDestination(for: String.self) { items, location in
                        if let first = items.first, let noteID = UUID(uuidString: first) {
                            NotificationCenter.default.post(name: .moveNoteRequest, object: nil, userInfo: ["noteID": noteID, "folderID": f.id])
                            return true
                        }
                        return false
                    } isTargeted: { _ in }
                }
                
            case.note(let n):
                Button {
                    onSelect(n.id)
                } label: {
                    Spacer()
                        .frame(width: 18)
                    
                    Text(n.title)
                        .coteFont(.text2,
                                  color: isHover || isSelected ? .textStrong : .textDefault)
                        .frame(height: 18) //tag 높이
                }
                .buttonStyle(.plain)
                .draggable(n.id.uuidString)
            }
            
            Spacer()
        }
        .padding(.vertical, 5)
        .padding(.horizontal, 5)
        .frame(maxWidth: .infinity, minHeight: 26)
        .background(
            isSelected ? Color.actionDefault
            : (isHover ? Color.actionDefault : Color.clear)
        )
        .cornerRadius(8)
        .onHover { (entered) in
            if isRenamingFolder {
                isHover = false
            } else {
                isHover = entered
            }
        }
        .onChange(of: isRenamingFolder, {
            if isRenamingFolder {
                focusField = .folder
            }
        })
        
        if isExpanded {
            ForEach(item.children) { child in
                ListCell(
                    expandedIDs: $expandedIDs,
                    renamingFolderID: $renamingFolderID,
                    renamingName: $renamingName,
                    selectedNoteID: selectedNoteID,
                    item: child,
                    depth: depth + 1,
                    onSelect: onSelect,
                    onCommitRename: onCommitRename
                )
            }
        }
    }
    
    private func toggleExpansion() {
        guard case .folder(let f) = item else { return }
        if isExpanded { expandedIDs.remove(f.id) }
        else           { expandedIDs.insert(f.id) }
    }
}

extension Notification.Name {
    static let moveNoteRequest = Notification.Name("MoveNoteRequest")
}
