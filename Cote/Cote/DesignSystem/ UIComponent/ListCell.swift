//
//  noteCell.swift
//  Cote
//
//  Created by 김예림 on 7/23/25.
//

import SwiftUI

struct ListCell: View {
    @State var isHover = false
    @Binding var expandedIDs: Set<UUID>
    
    let noteID: UUID?
    let item: NoteItems
    let depth: Int
    
    let onSelect: (UUID) -> Void
    
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
        case .note(let n): return noteID == n.id
        }
    }
    
    var body: some View {
        HStack(spacing: 0) {
            Spacer()
                .frame(width: 10 * CGFloat(depth))
            
            switch item {
            case.folder(let f):
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
                } isTargeted: { _ in
                    true
                }
                
            case.note(let n):
                Button {
                    onSelect(n.id)
                } label: {
                    Spacer()
                        .frame(width: 18)
                    
                    Text(n.title)
                        .coteFont(.title2,
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
            isHover = entered
        }
        
        if isExpanded {
            ForEach(item.children) { child in
                ListCell(
                    isHover: false,
                    expandedIDs: $expandedIDs,
                    noteID: noteID,
                    item: child,
                    depth: depth + 1,
                    onSelect: onSelect
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

struct FolderCell: View {
    var isExpanded: Bool
    let folder: Folder
    @Binding var isHover: Bool
    var body: some View {
        HStack(spacing: 0) {
            if isExpanded {
                Image("arrow_down")
                    .foregroundStyle(.iconSecondary)
            } else {
                Image("arrow_right")
                    .foregroundStyle(.iconSecondary)
            }
            Text(folder.name)
                .coteFont(.title2,
                          color: isHover ? .textStrong : .textDefault)
        }
    }
}

extension Notification.Name {
    static let moveNoteRequest = Notification.Name("MoveNoteRequest")
}
