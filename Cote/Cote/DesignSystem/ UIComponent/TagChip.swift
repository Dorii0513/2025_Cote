//
//  TagChip.swift
//  Cote
//
//  Created by 김예림 on 9/4/25.
//

import SwiftUI

struct TagChip: View {
    let tag: String
    let action: () -> Void

    var body: some View {
        
        Button {
            action()
        } label: {
            Text(tag)
                .coteFont(.tag, color: .textTag)
        }
        .buttonStyle(.plain)
        .padding(.vertical, 2)
        .padding(.horizontal, 6)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(.bgTag)
        )
    }
}
