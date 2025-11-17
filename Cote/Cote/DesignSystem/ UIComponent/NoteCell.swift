//
//  NoteCell.swift
//  Cote
//
//  Created by 김예림 on 11/18/25.
//

import SwiftUI

struct NoteCell: View {
    let selectedNote: FocusedNote?
    let mode: CellMode
    let onSelect: () -> Void
    
    var body: some View {
        HStack {
            if mode == .button {
                Button {
                    onSelect()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                        if let note = selectedNote {
                            Text(note.title)
                                .coteFont(.text2, color: .textDefault)
                        }
                    }
                    .padding(.vertical, 5)
                    .padding(.horizontal, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(.actionDefault)
                    )
                }
                .buttonStyle(.plain)
            } else {
                HStack(spacing: 4) {
                    if let note = selectedNote {
                        Text(note.title)
                            .coteFont(.text2, color: .textSelected)
                    }
                    Button {
                        onSelect()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 10))
                            .foregroundStyle(.textSelected)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.vertical, 5)
                .padding(.horizontal, 10)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(.aiMuted)
                )
            }
        }
    }
}

enum CellMode {
    case label, button
}
