//
//  UIState.swift
//  Cote
//
//  Created by 김예림 on 10/3/25.
//

import SwiftUI

@MainActor
final class UIState: ObservableObject {
    @Published var isSidebarOpen = true
    @Published var isFolderView = true
    @Published var isSearchView = false
    
    @AppStorage("previousNoteID") private var previousNoteIDString: String?
    @AppStorage("selectedNoteID") private var selectedNoteIDString: String?
    
    var previousNoteID: UUID? {
        get {
            guard let string = previousNoteIDString else { return nil }
            return UUID(uuidString: string)
        }
        set {
            previousNoteIDString = newValue?.uuidString
            objectWillChange.send()
        }
    }

    var selectedNoteID: UUID? {
        get {
            guard let string = selectedNoteIDString else { return nil }
            return UUID(uuidString: string)
        }
        set {
            selectedNoteIDString = newValue?.uuidString
            objectWillChange.send()
        }
    }
    
    func toggleSidebar() { isSidebarOpen.toggle() }
}

struct FocusRequest: Equatable {
    let target: FocusTarget
    let id: UUID
}

enum FocusTarget: Hashable {
    case addFolder
    case addNote
    case folder
    case note
    case tag
    case chat
    case search
}
