//
//  menuButton.swift
//  Cote
//
//  Created by 김예림 on 7/23/25.
//

import SwiftUI

struct MenuButton: View {
    @State var isHover = false
    
    @Binding var selected: Bool
    let icon: Icon
    
    private var iconColor: Color {
        switch icon.size {
        case .large:
            return selected ? .iconSelected : (isHover ? .iconSelected : .textLabelDefault)
        case .small:
            return isHover ? .iconSelected : .textLabelDefault
        }
    }
    
    private var backgroundColor: Color {
        switch icon.size {
        case .large:
            return selected ? .actionDefault : (isHover ? .actionDefault : .clear)
        case .small:
            return isHover ? .actionDefault : .clear
        }
    }
    
    var body: some View {
        
        ZStack {
            Button {
                selected = true
            } label: {
                Image(icon.name)
                    .foregroundStyle(iconColor)
                    .padding(icon.size == .large ? 6 : 5)
            }
            .buttonStyle(.plain)
            .background(backgroundColor)
            .cornerRadius(8)
            .onHover(perform: { hovering in
                self.isHover = hovering
            })
        }
    }
}
