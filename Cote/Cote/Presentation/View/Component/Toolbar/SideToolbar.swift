//
//  Toolbar.swift
//  Cote
//
//  Created by 김예림 on 9/6/25.
//

import SwiftUI

struct SideToolbar: View {
    @State private var selectedButtonID: UUID?
    @Binding var offset: CGFloat
    @EnvironmentObject private var state: UIState

    private var visibleIcons: [Icon] {
        if state.isSidebarOpen {
            return CoteIcon.toolbarIcons
        } else {
            return CoteIcon.toolbarIcons.filter { $0.name == "sidebar" }
        }
    }

    var body: some View {
        HStack(spacing: 4) {
            Spacer()
            HStack(spacing: 2) {
                ForEach(visibleIcons) { button in
                    MenuButton(
                        selected: Binding(
                            get: { selectedButtonID == button.id },
                            set: { if $0 { selectedButtonID = button.id } }
                        ),
                        icon: button
                    )
                    .transition(.opacity.combined(with: .scale))
                }
            }
            .padding(.trailing, 12)
        }
        .frame(alignment: .leading)
        .frame(width: state.isSidebarOpen ? offset : 125, height: 42)  //높이 고정
        .animation(.snappy(duration: 0.2), value: state.isSidebarOpen)
        .onAppear {
            if selectedButtonID == nil {
                if let folder = visibleIcons.first(where: { $0.name == "folder" }) {
                    selectedButtonID = folder.id
                }
            }
        }
    }
}
