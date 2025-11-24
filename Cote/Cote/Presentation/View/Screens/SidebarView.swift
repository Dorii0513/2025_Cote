//
//  Sidebar.swift
//  Cote
//
//  Created by 김예림 on 11/24/25.
//

import SwiftUI

struct SidebarView: View {
    @EnvironmentObject private var state: UIState
    @Binding var width: CGFloat

    var body: some View {
        ZStack {
            VStack(spacing: 4) {
                Rectangle()
                    .frame(height: 1)
                    .foregroundStyle(.actionDefault)
                if state.isFolderView {
                    FolderView()
                }
                if state.isSearchView {
                    SearchView()
                }
            }
        }
        .frame(width: width)
        .frame(minHeight: 700)
        .background(Color.clear)
    }
}
