//
//  CoteApp.swift
//  Cote
//
//  Created by 김예림 on 6/17/25.
//

import SwiftUI
import RealmSwift
import Foundation

@main
struct CoteApp: SwiftUI.App {
    init() {
        
        let storeURL = PersistentStoreRecovery.debugStoreURL(baseName: "CoteRealm")
        
        let config = Realm.Configuration(
            fileURL: storeURL,
            schemaVersion: 1,
            migrationBlock: { migration, oldSchemaVersion in
                if oldSchemaVersion < 1 {
                    // 'tags' property added to NoteObject; no manual migration is required.
                }
            }
        )
        Realm.Configuration.defaultConfiguration = config
        
        do {
            _ = try Realm(configuration: config)
        } catch {
            // 버전 다운그레이드 등으로 열기에 실패하면 스토어 정리 후 재시도
            PersistentStoreRecovery.removeStoreIfIncompatible(at: storeURL)
            let retryConfig = Realm.Configuration(
                fileURL: storeURL,
                schemaVersion: 1,
                migrationBlock: { migration, oldSchemaVersion in
                    if oldSchemaVersion < 1 {
                    }
                }
            )
            Realm.Configuration.defaultConfiguration = retryConfig
            do {
                _ = try Realm(configuration: retryConfig)
            } catch {
                fatalError("Realm init failed after recovery: \(error)")
            }
        }
        
        #if DEBUG
        print("Realm file:", Realm.Configuration.defaultConfiguration.fileURL?.path ?? "nil")
        #endif
    }
    var body: some Scene {
        WindowGroup {
            if #available(macOS 26.0, *) {
                HomeView()
                    .navigationTitle("")
                    .toolbarBackground(.hidden, for: .windowToolbar)
                    .environment(\.realmConfiguration, Realm.Configuration.defaultConfiguration)
                    .task {
                        await EmbeddingBackFill().run()
                    }
            } else {
                // Minimal fallback for older macOS versions to satisfy availability
                Text("Unsupported macOS version")
                    .padding()
            }
        }
        .windowResizability(.contentSize)
    }
}
