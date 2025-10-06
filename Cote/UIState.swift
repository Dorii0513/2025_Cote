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
    func toggleSidebar() { isSidebarOpen.toggle() }
}
