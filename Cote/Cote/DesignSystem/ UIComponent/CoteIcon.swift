//
//  CoteIcon.swift
//  Cote
//
//  Created by 김예림 on 8/3/25.
//

import Foundation
import SwiftUI

struct Icon: Identifiable {
    let id = UUID()
    let name: String
    let size: IconSize
    let action: @MainActor (UIState) -> Void
}

enum IconSize: String {
    case small
    case large
}

enum CoteIcon {
    static let toolbarIcons: [Icon] = [
        Icon(name: "folder", size: .large) {state in
            print("폴더 열기")
            state.isFolderView = true
            state.isSearchView = false
        },
        Icon(name: "search", size: .large) {state in
            print("검색 열기")
            state.isSearchView = true
            state.isFolderView = false
        },
        Icon(name: "sidebar", size: .large) {state in
            state.toggleSidebar()
            print(state.isSidebarOpen)
        }
    ]
    
    static let addNote = Icon(name: "addNote", size: .small) {state in
        print("노트 추가")
        state.addNote = true
    }
    static let addFolder = Icon(name: "addFolder", size: .small) {state in
        print("폴더 추가")
        state.addFolder = true
    }
    static let filter = Icon(name: "filter", size: .small) {_ in
        print("필터 열기")
    }
}

