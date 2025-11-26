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
    private let updateNoteUseCase: UpdateNoteUseCase
    private let fetchUseCase: FetchNotesUseCase
    private let generateUseCase: GenerateCommentUseCase
    private let deleteNoteUseCase: DeleteNoteUseCase
    private let deleteTagUseCase: DeleteTagUseCase
    
    // 노트 편집
    @Published private(set) var currentNoteID: UUID? = nil
    @Published var content: String = ""
    @Published var title: String = ""
    @Published var noteTags: [Tag] = []
    @Published var updatedAt: Date? = nil
    @Published var language: String = ""
    @Published private var contentBeforeComment: String? = nil
    @Published var showUndoButton: Bool = false
    
    // 태그 생성
    @Published var generatedTags: [Tag] = []
    @Published var showTags: Bool = false
    @Published var isGenerating: Bool = false
    @Published var isLoading: Bool = false
    
    // 주석 생성
    @Published var aiComments: [AIComment] = []
    
    var canUndoComments: Bool {
        contentBeforeComment != nil
    }
    
    init(
        tagUseCase: GenerateTagsUseCase,
        updateNoteUseCase: UpdateNoteUseCase,
        fetchUseCase: FetchNotesUseCase,
        generateUseCase: GenerateCommentUseCase,
        deleteNoteUseCase: DeleteNoteUseCase,
        deleteTagUseCase: DeleteTagUseCase
    ) {
        self.tagUseCase = tagUseCase
        self.updateNoteUseCase = updateNoteUseCase
        self.fetchUseCase = fetchUseCase
        self.generateUseCase = generateUseCase
        self.deleteNoteUseCase = deleteNoteUseCase
        self.deleteTagUseCase = deleteTagUseCase
    }
    
    convenience init() {
        self.init(
            tagUseCase: DefaultGenerateTagsUseCase(),
            updateNoteUseCase: DefaultUpdateNoteUseCase(),
            fetchUseCase: DefaultFetchNotesUseCase(),
            generateUseCase: DefaultGenerateCommentUseCase(),
            deleteNoteUseCase: DefaultDeleteNoteUseCase(),
            deleteTagUseCase: DefaultDeleteTagUseCase()
        )
    }

    //MARK: - 태그 관련
    func addNewTag(_ tag: Tag) {
        guard !noteTags.contains(where: { $0.id == tag.id }) else { return }
        noteTags.append(tag)
    }

    func showSuggestions() {
        showTags = true
        if !isGenerating {
            Task { await generateTags() }
        }
    }

    func hideSuggestions() {
        showTags = false
    }

    func generateTags() async {
        guard !isGenerating, !content.isEmpty else {
            print("⚠️ [generateTags] blocked - isGenerating: \(isGenerating), content isEmpty: \(content.isEmpty)")
            return
        }
        
        isGenerating = true
        generatedTags = []
        
        defer { isGenerating = false }
        
        do {
            let tagNames = try await tagUseCase.generateTags(content: content)
            generatedTags = tagNames.map { Tag(name: $0) }
            print("✅ [generateTags] success: \(tagNames)")
        } catch {
            print("❌ [TagGeneration] Error: \(error.localizedDescription)")
            generatedTags = []
        }
    }
    
    func deleteTag(noteID: UUID, tagName: String) async {
        do {
            try await deleteTagUseCase.execute(noteID: noteID, tagName: tagName)
            self.noteTags.removeAll { $0.name == tagName }
        } catch {
            print("[DeleteTag] : \(error)")
        }
    }
    
    // MARK: - Note
    func updateNote(by id: UUID, save: NoteSaveField) async {
        
        guard !isLoading else {
            print("⛔️ save blocked - note is loading")
            return
        }
        
        do {
            switch save {
            case .title:
                try await updateNoteUseCase.execute(id: id, save: .title(title))
            case .content:
                try await updateNoteUseCase.execute(id: id, save: .content(content))
            case .tags:
                try await updateNoteUseCase.execute(id: id, save: .tags(noteTags))
            case .language:
                try await updateNoteUseCase.execute(id: id, save: .language(language))
            }
        } catch {
            print("[NoteSave] failed: \(type(of: error)) - \(error.localizedDescription)")
        }
    }
    
    // 선택 노트 로드
    func loadNote(by id: UUID) async {
        
        isLoading = true
        currentNoteID = id
        
        do {
            // 첫 시도
            if let note = try await fetchUseCase.execute(noteID: id) {
                apply(note)
                
                try await Task.sleep(nanoseconds: 50_000_000)
                isLoading = false
                return
            }
            
            // 재시도
            try await Task.sleep(nanoseconds: 150_000_000)
            if let note = try await fetchUseCase.execute(noteID: id) {
                apply(note)
                
                try await Task.sleep(nanoseconds: 50_000_000)
                isLoading = false
                return
            }
            
            isLoading = false
        } catch {
            print("❌ [VM] load error=", error)
            isLoading = false
        }
    }
    
    private func apply(_ note: Note) {
        objectWillChange.send()
        
        self.title = note.title
        self.content = note.content
        self.noteTags = note.tags
        self.updatedAt = note.updatedAt
        self.language = note.language.isEmpty ? "plaintext" : note.language
    }
    
    func deleteNote(id: UUID) {
        Task {
            do {
                try await deleteNoteUseCase.execute(id: id)
            } catch {
                print("[SideBarVM] delete failed: \(error)")
            }
        }
    }
    
    //MARK: - Comment
    func applyCommentsToCode() {
        guard !aiComments.isEmpty else { return }
        
        contentBeforeComment = content
        
        var lines = content.components(separatedBy: "\n")
        let commentDict = Dictionary(uniqueKeysWithValues: aiComments.map { ($0.line, $0.text) })
        
        for (lineNum, comment) in commentDict.sorted(by: { $0.key < $1.key }) {
            let arrayIndex = lineNum - 1
            if arrayIndex >= 0 && arrayIndex < lines.count {
            } else { }
        }
        
        for lineNumber in commentDict.keys.sorted(by: >) {
            let arrayIndex = lineNumber - 1
            
            guard arrayIndex >= 0 && arrayIndex < lines.count else {
                continue
            }
            
            let originalLine = lines[arrayIndex]
            let comment = commentDict[lineNumber] ?? ""
            
            // 이미 주석이 있으면 추가 X
            if originalLine.trimmingCharacters(in: .whitespaces).hasPrefix("//") {
                continue
            }
            
            // 빈 줄이면 넘어가기
            if originalLine.trimmingCharacters(in: .whitespaces).isEmpty {
                continue
            }
            
            // 아래 줄의 들여쓰기 가져옴
            let leadingWhitespace = originalLine.prefix(while: { $0.isWhitespace })
            
            let finalComment = comment.hasPrefix("//") ? comment : "// " + comment
            
            // 주석을 해당 줄 위에 추가 (들여쓰기 고려)
            let commentLine = String(leadingWhitespace) + finalComment
            lines.insert(commentLine, at: arrayIndex)
        }
        
        content = lines.joined(separator: "\n")
        aiComments = []
        
        DispatchQueue.main.async {
            self.showUndoButton = true
        }
    }
    
    func generateComments() async {
        do {
            
            let comments = try await generateUseCase.execute(code: content)
            self.aiComments = comments
            applyCommentsToCode()
            
        } catch { self.aiComments = [] }
    }
    
    func undoComments() {
        guard let previousContent = contentBeforeComment else { return }
        content = previousContent
        contentBeforeComment = nil
        aiComments = []
        
        DispatchQueue.main.async {
            self.showUndoButton = false
        }
    }
}

struct AIComment: Identifiable, Equatable {
    let id: UUID
    let line: Int
    let text: String
}
