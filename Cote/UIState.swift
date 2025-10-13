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
    @Published var addNote = false
    @Published var addFolder = false
    @Published var selectedNoteID: UUID?

    func toggleSidebar() { isSidebarOpen.toggle() }
}
