//
//  ContentViewModel.swift
//  Cote
//
//  Created by 김예림 on 9/4/25.
//

import Foundation
import SwiftUI
import RealmSwift

@MainActor
final class ContentViewModel: ObservableObject {
    
    private let tagUseCase: GenerateTagsUseCase
    private let saveUseCase: SaveNoteUseCase
    private let fetchUseCase: FetchNotesUseCase
    
    @Published var content: String
    @Published var title: String = "Untitled"
    @Published var generatedTags: [Tag] = []
    @Published var noteTags: [Tag] = []
    @Published var showTags: Bool = false
    @Published var isGenerating: Bool = false
    @Published private(set) var currentNoteID: UUID? = nil
    @Published var isLoading: Bool = false
    
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
    func saveCurrentNote(by: UUID) async {
        let safeTitle = title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Untitled" : title
        let note = Note(id: by, title: safeTitle, content: content, tags: noteTags)
        do {
            try await saveUseCase.execute(note: note)
        } catch {
            print("[NoteSave] failed: \(type(of: error)) - \(error.localizedDescription)")
        }
    }
    
    func loadNote(by id: UUID) async {
            if currentNoteID == id && !content.isEmpty { return }
            isLoading = true
            defer { isLoading = false; currentNoteID = id }
            do {
                print("[VM] loadNote id=", id)
                guard let note = try await fetchUseCase.execute(noteID: id) else { return }
                self.title = note.title
                self.content = note.content
                self.noteTags = note.tags
                print("[VM] loaded title=\(title) len=\(content.count)")
            } catch {
                print("[VM] load error=", error)
            }
        }
    
    func probeNoteDirect(id: UUID) {
        do {
            let realm = try Realm()
            if let obj = realm.object(ofType: NoteObject.self, forPrimaryKey: id) {
                print("[Probe] FOUND id=", obj.id, " title=", obj.title)
            } else {
                print("[Probe] NOT FOUND id=", id)
            }
        } catch {
            print("[Probe] Realm open error:", error)
        }
    }
}

