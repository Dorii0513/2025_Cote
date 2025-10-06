//
//  ContentViewModel.swift
//  Cote
//
//  Created by 김예림 on 9/4/25.
//

import Foundation
import SwiftUI

@MainActor
final class ContentViewModel: ObservableObject {
    
    private let tagUseCase: GenerateTagsUseCase
    private let saveUseCase: SaveNoteUseCase
    private let fetchUseCase: FetchNotesUseCase
    
    @Published var content: String
    @Published var title: String = "Untitled"
    @Published var generatedTags: [String] = []
    @Published var noteTags: [Tag] = []
    @Published var showTags: Bool = false
    @Published var isGenerating: Bool = false
    
    init(
        initialContent: String,
        tagUseCase: GenerateTagsUseCase,
        saveUseCase: SaveNoteUseCase,
        fetchUseCase: FetchNotesUseCase
    ) {
        self.content = initialContent
        self.tagUseCase = tagUseCase
        self.saveUseCase = saveUseCase
        self.fetchUseCase = fetchUseCase
    }

    convenience init(initialContent: String) {
        self.init(
            initialContent: initialContent,
            tagUseCase: DefaultGenerateTagsUseCase(),
            saveUseCase: DefaultSaveNoteUseCase(),
            fetchUseCase: DefaultFetchNotesUseCase()
        )
    }
    
    func addNewTag(_ tag: Tag) {
        noteTags.append(tag)
    }
    
    func toggleTags() {
        showTags = true
        if showTags { Task { await generateTags() } } else { generatedTags = [] }
    }
    
    func insertTag(_ tag: String) {
        let insertion = "// #\(tag)\n"
        content += insertion
    }
    
    func generateTags() async {
        guard !isGenerating else { return }
        isGenerating = true
        defer { isGenerating = false }
        do {
            generatedTags = try await tagUseCase.generateTags(content: content)
        } catch {
            print("[TagGeneration] failed: \(error)")
        }
    }
    
    // MARK: - Persistence (Save / Load)
    func saveCurrentNote() async {
        let safeTitle = title.isEmpty ? "Untitled" : title
        let note = Note(title: safeTitle, content: content, tags: noteTags)
        do {
            try await saveUseCase.execute(note: note)
        } catch {
            print("[NoteSave] failed: \(error)")
        }
    }

    func loadMostRecentNote() async {
        do {
            let notes = try await fetchUseCase.execute()
            if let first = notes.first {
                self.title = first.title
                self.content = first.content
            }
        } catch {
            print("[NoteFetch] failed: \(error)")
        }
    }
}

