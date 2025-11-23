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
    private let generateUseCase: GenerateCommentUseCase
    private let deleteUseCase: DeleteNoteUseCase
    
    // 노트 편집
    @Published private(set) var currentNoteID: UUID? = nil
    @Published var content: String = ""
    @Published var title: String = ""
    @Published var noteTags: [Tag] = []
    @Published var updatedAt: Date? = nil
    @Published var language: String = ""
    
    // 태그 생성
    @Published var generatedTags: [Tag] = []
    @Published var showTags: Bool = false
    @Published var isGenerating: Bool = false
    @Published var isLoading: Bool = false
    
    // 주석 생성
    @Published var aiComments: [AIComment] = []
    
    init(
        tagUseCase: GenerateTagsUseCase,
        saveUseCase: SaveNoteUseCase,
        fetchUseCase: FetchNotesUseCase,
        generateUseCase: GenerateCommentUseCase,
        deleteUseCase: DeleteNoteUseCase
    ) {
        self.tagUseCase = tagUseCase
        self.saveUseCase = saveUseCase
        self.fetchUseCase = fetchUseCase
        self.generateUseCase = generateUseCase
        self.deleteUseCase = deleteUseCase
    }
    
    convenience init() {
        self.init(
            tagUseCase: DefaultGenerateTagsUseCase(),
            saveUseCase: DefaultSaveNoteUseCase(),
            fetchUseCase: DefaultFetchNotesUseCase(),
            generateUseCase: DefaultGenerateCommentUseCase(),
            deleteUseCase: DefaultDeleteNoteUseCase()
        )
    }
    
    //MARK: - 태그 관련
    func addNewTag(_ tag: Tag) {
        guard !noteTags.contains(where: { $0.id == tag.id }) else { return } // 중복 태그 방지
        noteTags.append(tag)
    }
    
    func showSuggestions() {
        guard !showTags else { return }
        showTags = true
        Task { await generateTags() }
    }
    
    func hideSuggestions() {
        guard showTags else { return }
        showTags = false
        generatedTags = []
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
    
    // MARK: - Note
    
    // 노트 저장
    func saveCurrentNote(by id: UUID) async {
        
        guard !isLoading else {
            print("⛔️ save blocked - note is loading")
            return
        }
        
        let safeTitle = title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Untitled" : title
        let safeDate = updatedAt ?? Date()
        
        let note = Note(
            id: id,
            title: safeTitle,
            content: content,
            tags: noteTags,
            sortIndex: 0,
            updatedAt: safeDate,
            language: language
        )
        do {
            try await saveUseCase.execute(note: note)
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
                try await deleteUseCase.execute(id: id)
            } catch {
                print("[SideBarVM] delete failed: \(error)")
            }
        }
    }
    
    //MARK: - Comment
    func applyCommentsToCode() {
        guard !aiComments.isEmpty else { return }
        
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
    }
    
    func generateComments() async {
        do {
            
            let comments = try await generateUseCase.execute(code: content)
            self.aiComments = comments
            applyCommentsToCode()
            
        } catch { self.aiComments = [] }
    }
}

struct AIComment: Identifiable, Equatable {
    let id: UUID
    let line: Int
    let text: String
}

struct AICommentResponse: Codable {
    struct Comment: Codable {
        let line: Int
        let comment: String
    }
    
    let comments: [Comment]
}
