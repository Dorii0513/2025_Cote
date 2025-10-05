//
//  CoteApp.swift
//  Cote
//
//  Created by 김예림 on 6/17/25.
//

import SwiftUI

@main
struct CoteApp: App {
    @StateObject private var state = UIState()
    var body: some Scene {
        WindowGroup {
            MainView()
                .toolbar(removing: .title)
                .toolbarBackgroundVisibility(.hidden, for: .windowToolbar)
                .environmentObject(state)
        }
        .windowResizability(.contentSize)
    }
}
