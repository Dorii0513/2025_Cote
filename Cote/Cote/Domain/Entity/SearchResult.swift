//
//  SearchResult.swift
//  Cote
//
//  Created by 김예림 on 11/1/25.
//

import Foundation

public struct SearchResult {
    public let noteID: UUID
    public let title: String
    public let preview: String
    public let score: Double
    public init(noteID: UUID, title: String, preview: String, score: Double = 0) {
        self.noteID = noteID
        self.title  = title
        self.preview = preview
        self.score  = score
    }
}
