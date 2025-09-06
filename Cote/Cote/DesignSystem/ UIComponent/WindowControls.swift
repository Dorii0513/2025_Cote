//
//  WindowControls.swift
//  Cote
//
//  Created by 김예림 on 9/6/25.
//

import SwiftUI
import AppKit

struct WindowControls: View {
    weak var window: NSWindow?
    
    var body: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(Color.red)
                .frame(width: 12, height: 12)
                .onTapGesture {
                    window?.performClose(nil)
                }
            
            Circle()
                .fill(Color.yellow)
                .frame(width: 12, height: 12)
                .onTapGesture {
                    window?.miniaturize(nil)
                }
            
            Circle()
                .fill(Color.green)
                .frame(width: 12, height: 12)
                .onTapGesture {
                    window?.zoom(nil)
                }
        }
        .padding(.horizontal, 16)
    }
}
#Preview {
    WindowControls()
}
