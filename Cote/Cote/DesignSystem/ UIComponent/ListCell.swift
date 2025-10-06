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
    
    let item: NoteItems
    let depth: Int
    
    // expandedIDs 값이 존재할 때 true
    private var isExpanded: Bool {
        switch item {
        case .folder(let f): return expandedIDs.contains(f.id)
        case .note: return false
        }
    }
    
    var body: some View {
        HStack(spacing: 0) {
            Spacer()
                .frame(width: 20 * CGFloat(depth))
            
            switch item {
            case.folder(let f):
                Button {
                    toggleExpansion()
                } label: {
                    FolderCell(isExpanded: isExpanded, folder: f, isHover: $isHover)
                }
                .buttonStyle(.plain)
                
            case.note(let n):
                Button {
                    
                } label: {
                    Spacer()
                        .frame(width: 18)
                    
                    Text(n.title)
                        .coteFont(.title2,
                                  color: isHover ? .textStrong : .textDefault)
                        .frame(height: 18) //tag 높이
                }
                .buttonStyle(.plain)
            }
            
            Spacer()
        }
        .padding(.vertical, 5)
        .padding(.horizontal, 5)
        .frame(maxWidth: .infinity, minHeight: 26)
        .background(isHover ? Color.actionDefault : Color.clear)
        .cornerRadius(8)
        .onHover { (entered) in
            isHover = entered
        }
        
        if isExpanded {
            ForEach(item.children) { child in
                ListCell(
                    isHover: false,
                    expandedIDs: $expandedIDs,
                    item: child,
                    depth: depth + 1
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
