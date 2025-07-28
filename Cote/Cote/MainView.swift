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
        HStack {
            Sidebar()
            ContentView()
        }
        .background(Color.clear)
    }
}

#Preview {
    MainView()
}
