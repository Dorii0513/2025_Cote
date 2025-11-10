//
//  SearchResult.swift
//  Cote
//
//  Created by 김예림 on 11/1/25.
//

import Foundation

public struct SearchResult: Identifiable {
    public var id: UUID { noteID }
    
    public let noteID: UUID
    public let title: String
    public let content: String
    public let folders: [String]
    public let score: Double
    public init(noteID: UUID, title: String, content: String, folders: [String], score: Double = 0) {
        self.noteID = noteID
        self.title  = title
        self.content = content
        self.folders = folders
        self.score  = score
    }
}
