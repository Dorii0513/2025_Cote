//
//  Tag.swift
//  Cote
//
//  Created by 김예림 on 9/4/25.
//

import Foundation

struct Tag: Identifiable, Hashable {
    let id = UUID()
    var name: String
    
    init(name: String) {
        self.name = name
    }
}
