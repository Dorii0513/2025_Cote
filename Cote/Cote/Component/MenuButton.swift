//
//  menuButton.swift
//  Cote
//
//  Created by 김예림 on 7/23/25.
//

import SwiftUI

struct MenuButton: View {
    @State var isHover = false
    let name: String
    let action: () -> Void
    
    var body: some View {
        
        ZStack {
            Button {
                action()
            } label: {
                Image(name)
                    .foregroundStyle(.textLabelDefault)
                    .padding(5)
            }
            .buttonStyle(.plain)
            .background(isHover ? Color.actionDefault : Color.clear)
            .cornerRadius(5)
            .onHover(perform: { hovering in
                self.isHover = hovering
            })
        }
    }
}
