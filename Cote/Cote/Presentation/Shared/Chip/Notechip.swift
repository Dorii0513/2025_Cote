//
//  NoteChip.swift
//  Cote
//
//  Created by 김예림 on 11/18/25.
//

import SwiftUI

struct NoteChip: View {
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
                            .font(.system(size: 10))
                            .foregroundStyle(.textDefault)
                        if let note = selectedNote {
                            Text(note.title)
                                .coteFont(.text3, color: .textDefault)
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
//                    Image("language")
//                        .resizable()
//                        .frame(width: 12, height: 14)
//                        .foregroundStyle(.aiSecondary)
                    if let note = selectedNote {
                        Text(note.title)
                            .coteFont(.text3, color: .aiSecondary)
                    }
                    Button {
                        onSelect()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 10))
                            .foregroundStyle(.aiSecondary.opacity(0.7))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.vertical, 5)
                .padding(.horizontal, 10)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(.aiMuted.opacity(0.3))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(.aiMuted.opacity(0.8), lineWidth: 1)
                        )
                )
            }
        }
    }
}

enum CellMode {
    case label, button
}
