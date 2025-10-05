//
//  CoteIcon.swift
//  Cote
//
//  Created by 김예림 on 8/3/25.
//

import Foundation

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
        Icon(name: "folder", size: .large) {_ in 
            print("폴더 열기")
        },
        Icon(name: "search", size: .large) {_ in 
            print("검색 열기")
        },
        Icon(name: "sidebar", size: .large) {state in
            state.toggleSidebar()
            print(state.isSidebarOpen)
        }
    ]
    
    static let addNote = Icon(name: "addNote", size: .small) {_ in 
        print("노트 추가")
    }
    static let addFolder = Icon(name: "addFolder", size: .small) {_ in 
        print("폴더 추가")
    }
    static let filter = Icon(name: "filter", size: .small) {_ in 
        print("필터 열기")
    }
}

