//
//  SearchCell.swift
//  Cote
//
//  Created by 김예림 on 11/10/25.
//

import Foundation
import SwiftUI

struct SearchCell: View {
    @State private var isHover: Bool = false

    let selectedNoteID: UUID?
    let result: SearchResult
    let onSelect: () -> Void
    
    private var isSelected: Bool {
        return selectedNoteID == result.noteID
    }
    
    var body: some View {
        Button(action: onSelect) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(result.title)
                        .coteFont(.text1, color: isHover || isSelected ? .textSelected : .textDefault)
                    
                    if !result.folders.isEmpty {
                        HStack(spacing: 2) {
                            Image("folder")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 12,height: 12)
                                .foregroundStyle(.iconSecondary)
                            
                            Text(result.folders.joined(separator: " / "))
                            .coteFont(.text3, color: isHover || isSelected ? .textDefault : .textSecondary)
                        }
                    }
                    //                            HStack {
                    //                                Spacer()
                    //                                Text(String(format: "유사도: %.2f", result.score))
                    //                                    .font(.caption)
                    //                                    .foregroundColor(.gray)
                    //                            }
                }
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .foregroundStyle(isHover || isSelected ? .actionDefault : .clear)
            )
            .onHover { isHover = $0 }
        }
        .buttonStyle(.plain)
    }
}
