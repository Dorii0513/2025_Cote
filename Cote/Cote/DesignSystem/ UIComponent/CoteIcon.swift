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
    let action: () -> Void
}

enum IconSize: String {
    case small
    case large
}

enum CoteIcon {
    static let toolbarIcons: [Icon] = [
        Icon(name: "folder", size: .large) {
            print("폴더 열기")
        },
        Icon(name: "search", size: .large) {
            print("검색 열기")
        },
        Icon(name: "sidebar", size: .large) {
            print("사이드바 전환")
        }
    ]
    
    static let addNote = Icon(name: "addNote", size: .small) {
        print("노트 추가")
    }
    static let addFolder = Icon(name: "addFolder", size: .small) {
        print("폴더 추가")
    }
    static let filter = Icon(name: "filter", size: .small) {
        print("필터 열기")
    }
}
