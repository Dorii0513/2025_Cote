//
//  MainView.swift
//  Cote
//
//  Created by 김예림 on 7/26/25.
//

import SwiftUI
import AppKit

struct MainView: View {
    @State private var selectedButtonID: UUID?

    var body: some View {
        NavigationSplitView {
            ZStack {
                Color.bgSurfaceSidebar.ignoresSafeArea()
                
                Sidebar()
            }
            
            .toolbar(removing: .sidebarToggle)
            .toolbar(content: {
                ToolbarItem {
                    Spacer()
                }
                ToolbarItem(placement: .primaryAction, content: {
                    HStack(spacing: 4) {
                        Spacer()
                        ForEach (CoteIcon.toolbarIcons, id: \.id) { button in
                            MenuButton(selected: Binding(
                                get: { selectedButtonID == button.id },
                                set: { if $0 { selectedButtonID = button.id }}),
                                       icon: button,
                                       action: {
                            })
                        }
                    }
                })
            })
        } detail: {
            
        }
        .presentedWindowToolbarStyle(.unified)
    }
}

#Preview {
    MainView()
}
