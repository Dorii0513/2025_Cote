//
//  CoteApp.swift
//  Cote
//
//  Created by 김예림 on 6/17/25.
//

import SwiftUI
import RealmSwift

@main
struct CoteApp: SwiftUI.App {
    var body: some Scene {
        WindowGroup {
            MainView()
                .toolbar(removing: .title)
                .toolbarBackgroundVisibility(.hidden, for: .windowToolbar)
                .environmentObject(UIState())
                .environment(\.realmConfiguration, Realm.Configuration.defaultConfiguration)
        }
        .windowResizability(.contentSize)
    }
}
