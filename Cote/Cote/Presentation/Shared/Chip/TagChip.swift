//
//  TagChip.swift
//  Cote
//
//  Created by 김예림 on 9/4/25.
//

import SwiftUI

struct TagChip: View {
    let tag: String
    let isSugesstion: Bool
    let isDeletable: Bool
    let onDelete: () -> Void
    let onSelect: () -> Void
    
    var body: some View {
        if isSugesstion {
            Button {
                onSelect()
            } label: {
                Text(tag)
                    .coteFont(.tag, color: .textDefault)
                    .tracking(0.5)
                
                    .buttonStyle(.plain)
                    .padding(.vertical, 3)
                    .padding(.horizontal, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(.actionDefault )
                    )
            }
            .buttonStyle(.plain)
        } else {
            HStack {
                Text(tag)
                    .coteFont(.tag, color: .aiSecondary)
                    .tracking(0.5)
                if isDeletable {
                    Button {
                        onDelete()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 9))
                            .foregroundStyle(.aiSecondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 3)
            .padding(.horizontal, 6)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(.aiDark)
            )
        }
    }
}

//#Preview {
//    TagChip(tag: "어쩌고")
//}
