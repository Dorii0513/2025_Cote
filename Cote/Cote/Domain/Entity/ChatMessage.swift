//
//  ChatMesage.swift
//  Cote
//
//  Created by 김예림 on 11/16/25.
//

import SwiftUI

struct ChatMessage: Identifiable, Codable {
    
    enum Sender: String, Codable {
        case user
        case assistant
        case noteInfo
    }
    
    let id: UUID
    let sender: Sender
    let content: String
    let timestamp: Date
    
    init(sender: Sender,
         content: String,
         timestamp: Date = Date(),
         id: UUID = UUID()) {
        self.sender = sender
        self.content = content
        self.timestamp = timestamp
        self.id = id
    }
}
