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
    init() {
        let config = Realm.Configuration(
            schemaVersion: 1,
            migrationBlock: { migration, oldSchemaVersion in
                if oldSchemaVersion < 1 {
                    // 'tags' property added to NoteObject; no manual migration is required.
                }
            }
        )
        Realm.Configuration.defaultConfiguration = config
        #if DEBUG
        print("Realm file:", Realm.Configuration.defaultConfiguration.fileURL?.path ?? "nil")
        #endif
    }
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
