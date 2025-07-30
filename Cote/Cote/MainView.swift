//
//  MainView.swift
//  Cote
//
//  Created by 김예림 on 7/26/25.
//

import SwiftUI
import AppKit

struct MainView: View {
    var body: some View {
        NavigationSplitView {
            ZStack {
                Color.bgSurfaceSidebar.ignoresSafeArea()
                
                Sidebar()
                    .border(Color.blue, width: 4)
                    .toolbar(content: {
                        Button("Click Me") {
                            
                        }
                    })
            }
        } detail: {
            
        }
        .containerBackground(Color.bgSurfaceSidebar, for: .window)
        
    }
}

#Preview {
    MainView()
}
