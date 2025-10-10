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
    
    //해야 하는 것 : 사이드바에서 선택된 노트 아이디 값이랑 콘텐트 뷰랑 연결시키기. state 값 가져와서 띄우면 됨
    @Published var content: String
    @Published var title: String = "Untitled"
    @Published var generatedTags: [Tag] = []
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
    
    //MARK: - 태그 관련
    func addNewTag(_ tag: Tag) {
        guard !noteTags.contains(where: { $0.id == tag.id }) else { return } // 중복 태그 방지
        noteTags.append(tag)
    }
    
    func toggleTags() {
        showTags.toggle()
        if showTags {
            Task { await generateTags() }
        } else {
            generatedTags = []
        }
    }
    
    func insertTag(_ tag: String) {
        let insertion = "// #\(tag)\n"
        content += insertion
    }
    
    func generateTags() async {
        guard !isGenerating, !content.isEmpty else { return }
        isGenerating = true
        defer { isGenerating = false }
        
        do {
            let tagNames = try await tagUseCase.generateTags(content: content)
            generatedTags = tagNames.map { Tag(name: $0) }
        } catch {
            print("[TagGeneration] Error: \(error.localizedDescription)")
            generatedTags = []
        }
    }
    
    //MARK: - 노트 저장 / 로드
    func saveCurrentNote(noteID: UUID) async {
        let safeTitle = title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Untitled" : title
        let note = Note(id: noteID, title: safeTitle, content: content, tags: noteTags)
        do {
            try await saveUseCase.execute(note: note)
        } catch {
            print("[NoteSave] failed: \(error.localizedDescription)")
        }
    }
    
    func loadMostRecentNote() async {
        do {
            let notes = try await fetchUseCase.execute()
            if let first = notes.first {
                self.title = first.title
                self.content = first.content
                self.noteTags = first.tags
            }
        } catch {
            print("[NoteFetch] failed: \(error.localizedDescription)")
        }
    }
}
