//
//  Toolbar.swift
//  Cote
//
//  Created by 김예림 on 9/6/25.
//

import SwiftUI

struct Toolbar: View {
    let window: NSWindow?
    @State private var selectedButtonID: UUID?
    
    var body: some View {
        HStack(spacing: 4) {
            WindowControls(window: window)
            
            Spacer()
            
            HStack(spacing: 0) {
                ForEach (CoteIcon.toolbarIcons, id: \.id) { button in
                    MenuButton(selected: Binding(
                        get: { selectedButtonID == button.id },
                        set: { if $0 { selectedButtonID = button.id }}),
                               icon: button
                    )
                }
            }
            .padding(.trailing, 12)
        }
        .frame(height: 42)
    }
}
