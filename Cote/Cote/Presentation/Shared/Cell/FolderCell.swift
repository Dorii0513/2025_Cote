//
//  FolderCell.swift
//  Cote
//
//  Created by 김예림 on 11/25/25.
//

import Foundation
import SwiftUI

struct FolderCell: View {
    @EnvironmentObject private var viewModel: SideBarViewModel
    
    let isExpanded: Bool
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
                .coteFont(.text2,
                          color: isHover ? .textStrong : .textDefault)
        }
    }
}
